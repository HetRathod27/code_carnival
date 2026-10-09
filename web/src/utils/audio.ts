/**
 * Web Audio API synthesizer for civic check-in chimes.
 * No external media files needed; instant response across browsers.
 */

export function isSoundEnabled(): boolean {
  return localStorage.getItem('ql_sound_enabled') !== 'false';
}

export function setSoundEnabled(enabled: boolean): void {
  localStorage.setItem('ql_sound_enabled', enabled ? 'true' : 'false');
}

export function playCheckinChime(): void {
  if (!isSoundEnabled()) return;

  try {
    const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (!AudioCtx) return;

    const ctx = new AudioCtx();
    const now = ctx.currentTime;

    // Two-tone pleasant civic alert (E5 -> A5)
    const osc1 = ctx.createOscillator();
    const osc2 = ctx.createOscillator();
    const gain = ctx.createGain();

    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(659.25, now); // E5
    osc1.frequency.exponentialRampToValueAtTime(880.0, now + 0.12); // A5

    osc2.type = 'triangle';
    osc2.frequency.setValueAtTime(329.63, now); // E4 harmonic

    gain.gain.setValueAtTime(0.001, now);
    gain.gain.exponentialRampToValueAtTime(0.18, now + 0.04);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.38);

    osc1.connect(gain);
    osc2.connect(gain);
    gain.connect(ctx.destination);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 0.4);
    osc2.stop(now + 0.4);

    setTimeout(() => {
      ctx.close().catch(() => {});
    }, 500);
  } catch (err) {
    console.debug('Audio chime playback omitted:', err);
  }
}
