/** Supported total durations → number of 5-second Replicate clips. */
export function clipCountForDuration(totalSeconds: number): number {
  if (totalSeconds <= 5) return 1;
  return totalSeconds / 5;
}

export const EXTEND_DURATIONS = [5, 15, 30, 60] as const;
export const CLIP_SECONDS = 5;

export function isValidExtendDuration(seconds: number): boolean {
  return (EXTEND_DURATIONS as readonly number[]).includes(seconds);
}

export function clipObjectKey(jobId: string, clipIndex: number): string {
  return `outputs/${jobId}/clips/${String(clipIndex).padStart(3, '0')}.mp4`;
}

/** Under uploads/ so PUBLIC_ASSET_BASE_URL works like user input images. */
export function frameObjectKey(jobId: string, clipIndex: number): string {
  return `uploads/extend-frames/${jobId}/frame-${String(clipIndex).padStart(3, '0')}.jpg`;
}
