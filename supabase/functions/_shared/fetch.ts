/** Fetch with a wall-clock timeout (avoids 150s Supabase idle timeout). */
export async function fetchWithTimeout(
  input: string | URL | Request,
  init: RequestInit & { timeoutMs?: number } = {},
): Promise<Response> {
  const { timeoutMs = 30_000, ...rest } = init;
  return await fetch(input, {
    ...rest,
    signal: AbortSignal.timeout(timeoutMs),
  });
}

export function normalizeHttpsUrl(raw: string): string {
  const trimmed = raw.trim().replace(/\/$/, '');
  if (!trimmed) return trimmed;
  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  return `https://${trimmed}`;
}
