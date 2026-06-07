import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async (req: Request) => {
  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace('Bearer ', '');
  const { data: userResult } = await supabase.auth.getUser(token);
  if (!userResult?.user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
  }

  const userId = userResult.user.id;
  await supabase.from('likes').delete().eq('user_id', userId);
  await supabase.from('saved_posts').delete().eq('user_id', userId);
  await supabase.from('comments').delete().eq('user_id', userId);
  await supabase.from('notifications').delete().eq('user_id', userId);
  await supabase.from('notifications').delete().eq('actor_id', userId);
  await supabase.from('follows').delete().eq('follower_id', userId);
  await supabase.from('follows').delete().eq('following_id', userId);
  await supabase.from('reports').delete().eq('reporter_id', userId);
  await supabase.from('draft_generations').delete().eq('user_id', userId);
  await supabase.from('feed_items').delete().eq('creator_id', userId);
  await supabase.from('user_credits').delete().eq('user_id', userId);
  await supabase.from('profiles').delete().eq('id', userId);
  await supabase.from('generation_jobs').delete().eq('user_id', userId);
  await supabase.from('credits_ledger').delete().eq('user_id', userId);
  await supabase.auth.admin.deleteUser(userId);

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'content-type': 'application/json' },
  });
});
