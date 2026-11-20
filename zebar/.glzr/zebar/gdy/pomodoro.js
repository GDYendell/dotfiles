// Pomodoro timer state, shared by the bar (which owns and runs the timer)
// and the pomodoro panel (which sends commands over the 'gdy-panels'
// channel). Plain JS so both pages can import it.
//
// State: { mode: 'work' | 'break', minutes: { work, break },
//          endAt: ms timestamp while running, else null,
//          remaining: ms left when not running, done: just switched mode on expiry, not yet started }

export const DURATIONS = { work: [25, 45, 60, 90], break: [5, 10, 15] };
export const POMODORO_ICON = 'nf-md-timer_outline';

const fullMs = (s, mode = s.mode) => s.minutes[mode] * 60000;

export const initialState = () => ({
  mode: 'work',
  minutes: { work: 25, break: 5 },
  endAt: null,
  remaining: 25 * 60000,
  done: false,
});

export const remainingMs = (s, now) => (s.endAt ? Math.max(0, s.endAt - now) : s.remaining);

export function formatMs(ms) {
  const total = Math.ceil(ms / 1000);
  return `${String(Math.floor(total / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
}


// On expiry, switch to the other mode, stopped at its full duration.
export function complete(s) {
  const mode = s.mode === 'work' ? 'break' : 'work';
  return { ...s, mode, endAt: null, remaining: fullMs(s, mode), done: true };
}

// Applies a panel/bar command: { cmd: 'toggle' | 'reset' | 'mode' | 'duration', mode?, minutes? }.
export function reduce(s, c, now) {
  const reset = next => ({ ...next, endAt: null, remaining: fullMs(next), done: false });
  switch (c.cmd) {
    case 'toggle':
      if (s.endAt) return { ...s, endAt: null, remaining: remainingMs(s, now) };
      {
        const r = s.remaining > 0 ? s.remaining : fullMs(s);
        return { ...s, endAt: now + r, remaining: r, done: false };
      }
    case 'reset':
      return reset(s);
    case 'mode':
      return c.mode in DURATIONS ? reset({ ...s, mode: c.mode }) : s;
    case 'duration':
      return DURATIONS[s.mode].includes(c.minutes)
        ? reset({ ...s, minutes: { ...s.minutes, [s.mode]: c.minutes } })
        : s;
    default:
      return s;
  }
}
