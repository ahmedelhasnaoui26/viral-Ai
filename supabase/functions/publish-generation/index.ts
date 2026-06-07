import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    return json({ error: 'Unauthorized', hint: 'Missing bearer token' }, 401);
  }

  const { data: userResult, error: authError } = await supabase.auth.getUser(token);
  if (authError || !userResult?.user) {
    return json(
      { error: 'Unauthorized', hint: 'Please sign in again.' },
      401,
    );
  }
  const user = userResult.user;

  const body = await req.json().catch(() => null) as {
    generationJobId?: string;
    postToCommunity?: boolean;
    caption?: string;
    thumbnailUrl?: string;
    publishTemplate?: boolean;
    templateTitle?: string;
    templateDescription?: string;
    templateCategory?: string;
    templateAspectRatio?: string;
    templateIsPremium?: boolean;
  } | null;

  if (!body?.generationJobId) {
    return json({ error: 'generationJobId is required' }, 400);
  }

  const { data: job, error: jobError } = await supabase
    .from('generation_jobs')
    .select('id, user_id, prompt, style, duration_seconds, output_object_key, template_id, status')
    .eq('id', body.generationJobId)
    .single();
  if (jobError || !job) {
    return json({ error: 'Generation job not found' }, 404);
  }
  if (job.user_id !== user.id) {
    return json({ error: 'Forbidden' }, 403);
  }
  if (job.status !== 'completed' || !job.output_object_key) {
    return json(
      { error: 'Only completed generations can be published' },
      400,
    );
  }

  const videoKey = job.output_object_key as string;
  if (videoKey.startsWith('http')) {
    return json(
      {
        error: 'Video is not archived to R2 yet',
        hint: 'Wait for generation to finish saving to permanent storage.',
      },
      400,
    );
  }

  let templateId: string | null = job.template_id ?? null;

  if (body.publishTemplate) {
    const templateTitle = body.templateTitle?.trim() ?? '';
    const templateDescription = body.templateDescription?.trim() ?? '';
    const templateCategory = body.templateCategory?.trim() ?? 'Trending';
    const thumbnailUrl = body.thumbnailUrl?.trim() ?? '';
    if (!templateTitle || !templateDescription || !thumbnailUrl) {
      return json(
        { error: 'templateTitle, templateDescription and thumbnailUrl are required when publishTemplate=true' },
        400,
      );
    }
    const { data: insertedTemplate, error: templateError } = await supabase
      .from('templates')
      .insert({
        title: templateTitle,
        description: templateDescription,
        thumbnail_url: thumbnailUrl,
        prompt: job.prompt,
        style: job.style,
        duration: job.duration_seconds ?? 5,
        aspect_ratio: body.templateAspectRatio?.trim() || '9:16',
        category: templateCategory,
        creator_id: user.id,
        is_premium: body.templateIsPremium ?? false,
      })
      .select('id')
      .single();
    if (templateError || !insertedTemplate) {
      return json({ error: templateError?.message ?? 'Template insert failed' }, 500);
    }
    templateId = insertedTemplate.id as string;
  }

  if (!body.postToCommunity) {
    // Persist template linkage for this job even if user keeps video private.
    if (templateId != null && templateId != job.template_id) {
      await supabase
        .from('generation_jobs')
        .update({ template_id: templateId })
        .eq('id', job.id);
    }
    return json({ success: true, postCreated: false, templateId });
  }

  const caption = body.caption?.trim() ?? '';
  const { data: profile } = await supabase
    .from('profiles')
    .select('handle, display_name')
    .eq('id', user.id)
    .maybeSingle();
  const handle = typeof profile?.handle === 'string' ? profile.handle.trim() : '';
  const displayName =
    typeof profile?.display_name === 'string' ? profile.display_name.trim() : '';
  const creatorHandle =
    handle.length > 0
      ? handle
      : displayName.length > 0
        ? (displayName.startsWith('@') ? displayName : `@${displayName.replace(/\s+/g, '').toLowerCase()}`)
        : `@${user.id.substring(0, 8)}`;

  const { data: insertedFeed, error: feedError } = await supabase
    .from('feed_items')
    .insert({
      creator_id: user.id,
      creator_handle: creatorHandle,
      caption: caption.isEmpty ? job.prompt : caption,
      video_url: videoKey,
      thumbnail_url: body.thumbnailUrl?.trim().isEmpty ?? true
        ? null
        : body.thumbnailUrl?.trim(),
      template_id: templateId,
      generation_job_id: job.id,
    })
    .select('id')
    .single();
  if (feedError || !insertedFeed) {
    return json({ error: feedError?.message ?? 'Feed insert failed' }, 500);
  }

  if (templateId != null) {
    const { data: existingTemplate } = await supabase
      .from('templates')
      .select('uses_count')
      .eq('id', templateId)
      .maybeSingle();
    const usesCount =
      (typeof existingTemplate?.uses_count === 'number'
        ? existingTemplate.uses_count
        : 0) + 1;
    await supabase
      .from('templates')
      .update({ uses_count: usesCount })
      .eq('id', templateId);
  }

  if (templateId != null && templateId != job.template_id) {
    await supabase
      .from('generation_jobs')
      .update({ template_id: templateId })
      .eq('id', job.id);
  }

  return json({
    success: true,
    postCreated: true,
    feedItemId: insertedFeed.id,
    templateId,
  });
});
