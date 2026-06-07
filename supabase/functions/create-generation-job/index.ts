import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

import {
  buildPublicInputImageUrl,
  buildReplicateWebhookUrl,
  createPrediction,
} from '../_shared/replicate_service.ts';
import {
  clipCountForDuration,
  isValidExtendDuration,
} from '../_shared/extend_video_constants.ts';
import { ExtendVideoService } from '../_shared/extend_video_service.ts';
import { isGenerationLimitsDisabled } from '../_shared/generation_limits.ts';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const extendVideo = new ExtendVideoService(supabase);

serve(async (req: Request) => {
  const { objectKey, prompt, style, durationSeconds, templateId } = await req.json();
  if (!objectKey || !prompt || !style) {
    return new Response(JSON.stringify({ error: 'Missing objectKey, prompt, or style' }), {
      status: 400,
    });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    return new Response(
      JSON.stringify({
        error: 'Unauthorized',
        hint: 'Sign in to generate videos. No auth token was sent.',
      }),
      { status: 401, headers: { 'content-type': 'application/json' } },
    );
  }
  const { data: userResult, error: authError } = await supabase.auth.getUser(token);
  if (authError || !userResult?.user) {
    return new Response(
      JSON.stringify({
        error: 'Unauthorized',
        hint: 'Sign out and sign in again. Your session may have expired.',
        detail: authError?.message,
      }),
      { status: 401, headers: { 'content-type': 'application/json' } },
    );
  }
  const userId = userResult.user.id;

  let { data: credits } = await supabase
    .from('user_credits')
    .select('balance, plan')
    .eq('user_id', userId)
    .maybeSingle();

  if (!credits) {
    await supabase.from('user_credits').insert({
      user_id: userId,
      balance: 1,
      plan: 'free',
      watermark_enabled: true,
    });
    credits = { balance: 1, plan: 'free' };
  }

  const plan = (credits.plan as string) ?? 'free';
  const balance = Number(credits.balance) || 0;
  const limitsDisabled = isGenerationLimitsDisabled();

  if (!limitsDisabled) {
    if (plan === 'free') {
      const dayAgo = new Date(Date.now() - 86_400_000).toISOString();
      const { count } = await supabase
        .from('credits_ledger')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('reason', 'credit_consumed')
        .gte('created_at', dayAgo);
      if ((count ?? 0) >= 1) {
        return new Response(
          JSON.stringify({
            error: 'Daily limit reached',
            hint: 'Free plan allows 1 generation per day. Upgrade to Pro for more credits.',
          }),
          { status: 402, headers: { 'content-type': 'application/json' } },
        );
      }
    } else if (balance < 1) {
      return new Response(
        JSON.stringify({
          error: 'Insufficient credits',
          hint: 'Purchase a credit pack or upgrade your subscription.',
        }),
        { status: 402, headers: { 'content-type': 'application/json' } },
      );
    }
  }

  const duration = Number(durationSeconds) > 0 ? Number(durationSeconds) : 5;
  if (!isValidExtendDuration(duration)) {
    return new Response(
      JSON.stringify({
        error: 'Invalid duration',
        hint: 'Supported durations: 5, 15, 30, or 60 seconds.',
      }),
      { status: 400, headers: { 'content-type': 'application/json' } },
    );
  }

  const isExtended = duration > 5;
  const clipCount = clipCountForDuration(duration);

  const { data: inserted, error: insertError } = await supabase
    .from('generation_jobs')
    .insert({
      user_id: userId,
      input_object_key: objectKey,
      prompt,
      style,
      duration_seconds: duration,
      template_id: templateId ?? null,
      status: 'queued',
      provider: 'replicate',
      is_extended: isExtended,
      target_duration_seconds: duration,
      clip_count: clipCount,
    })
    .select('id')
    .single();
  if (insertError || !inserted) {
    return new Response(JSON.stringify({ error: insertError?.message ?? 'Insert failed' }), {
      status: 500,
    });
  }
  const jobId = inserted.id as string;

  if (!limitsDisabled) {
    if (plan === 'free') {
      await supabase.from('credits_ledger').insert({
        user_id: userId,
        delta: -1,
        reason: 'credit_consumed',
      });
    } else {
      await supabase
        .from('user_credits')
        .update({ balance: Math.max(0, balance - 1), updated_at: new Date().toISOString() })
        .eq('user_id', userId);
      await supabase.from('credits_ledger').insert({
        user_id: userId,
        delta: -1,
        reason: 'credit_consumed',
      });
    }
  }

  try {
    if (isExtended) {
      await extendVideo.startExtendedJob({
        jobId,
        inputObjectKey: objectKey,
        prompt,
        style,
        clipCount,
        targetDurationSeconds: duration,
      });

      const { data: job } = await supabase
        .from('generation_jobs')
        .select('provider_job_id, progress_percent, clip_count')
        .eq('id', jobId)
        .single();

      return new Response(
        JSON.stringify({
          jobId,
          status: 'processing',
          inputObjectKey: objectKey,
          isExtended: true,
          clipCount,
          progressPercent: job?.progress_percent ?? 2,
          replicatePredictionId: job?.provider_job_id ?? null,
        }),
        { headers: { 'content-type': 'application/json' } },
      );
    }

    const inputImageUrl = buildPublicInputImageUrl(objectKey);
    const webhookUrl = buildReplicateWebhookUrl();
    const prediction = await createPrediction({
      inputImageUrl,
      prompt,
      style,
      webhookUrl,
    });

    await supabase.from('generation_jobs').update({
      status: 'processing',
      provider_job_id: prediction.id,
    }).eq('id', jobId);

    return new Response(
      JSON.stringify({
        jobId,
        status: 'processing',
        inputObjectKey: objectKey,
        objectKey,
        outputUrl: null,
        replicatePredictionId: prediction.id,
      }),
      { headers: { 'content-type': 'application/json' } },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Replicate request failed';
    await supabase.from('generation_jobs').update({
      status: 'failed',
      error_message: message,
    }).eq('id', jobId);

    return new Response(
      JSON.stringify({
        error: message,
        hint:
          'Verify REPLICATE_API_TOKEN and REPLICATE_MODEL_VERSION in Supabase secrets.',
      }),
      { status: 502, headers: { 'content-type': 'application/json' } },
    );
  }
});
