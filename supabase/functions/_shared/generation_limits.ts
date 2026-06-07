/**
 * Testing override — set to false before production / when re-enabling limits.
 * Also honored: Supabase secret DISABLE_GENERATION_LIMITS=true
 */
export const DISABLE_GENERATION_LIMITS_DEV = true;

export function isGenerationLimitsDisabled(): boolean {
  if (DISABLE_GENERATION_LIMITS_DEV) return true;
  const env = Deno.env.get('DISABLE_GENERATION_LIMITS');
  return env === 'true' || env === '1';
}
