// Shared behaviour for popup panel widgets. Plain JS (no JSX) so it can be
// imported directly from the Babel-transformed panel pages.
//
// Import URLs must match the panel pages exactly so they share one React.
import { Fragment, createElement, useEffect, useLayoutEffect, useRef } from 'https://esm.sh/react@18.3.1?dev';
import * as zebar from 'https://esm.sh/zebar@3.3.1';
import { PhysicalPosition, PhysicalSize } from 'https://esm.sh/@tauri-apps/api@2.12.5/dpi';
import { currentMonitor } from 'https://esm.sh/@tauri-apps/api@2.12.5/window';

import { BAR_HEIGHT, PANEL_WIDTH } from './config.js';

document.documentElement.style.setProperty('--panel-width', `${PANEL_WIDTH}px`);

// Panels report open/closed here so the bar can underline the active icon
// and treat a second click on it as "close". The bar also answers history
// requests on it.
export const channel = new BroadcastChannel('gdy-panels');

const widget = zebar.currentWidget();
let closePanel = () => widget.close();

// Announces the panel, answers the bar's liveness pings, and closes on
// blur, Escape, or another panel window opening. Only one panel may be open:
// one that never had focus (e.g. from spam-clicking) would never blur.
export function setupPanel(name) {
  const instance = Math.random().toString(36).slice(2);
  let closing = false;
  function close() {
    if (closing) return;
    closing = true;
    channel.postMessage({ type: 'closed', panel: name, instance });
    widget.close();
  }

  closePanel = close;
  const announce = () => channel.postMessage({ type: 'open', panel: name, instance });
  announce();
  channel.addEventListener('message', ({ data }) => {
    if (data.type === 'ping' && data.panel === name && !closing) announce();
    if (data.type === 'open' && data.instance !== instance) close();
  });
  // A panel opened without a click (the pomodoro bell) belongs to a
  // background process, so Windows may not raise it. Re-assert top-most and
  // ask for focus.
  const win = widget.tauriWindow;
  win
    .setAlwaysOnTop(false)
    .then(() => win.setAlwaysOnTop(true))
    .then(() => win.setFocus())
    .catch(err => console.error(err));
  window.addEventListener('blur', close);
  window.addEventListener('keydown', e => e.key === 'Escape' && close());
  return close;
}

// Header cog that opens a Settings page (ms-settings:<page>) and closes the
// panel. Each page must be allowed for `explorer` in the panel's
// shellCommands in zpack.json.
export function SettingsButton({ page, title = 'Settings' }) {
  return createElement(
    'button',
    {
      className: 'icon-button',
      title,
      onClick: () => {
        zebar.shellExec('explorer', `ms-settings:${page}`).catch(err => console.error(err));
        closePanel();
      },
    },
    createElement('i', { className: 'nf nf-md-cog' }),
  );
}

// Fits the window height to the element. Sized in physical px from the
// webview's real scale, with a fixed width, so it can't drift.
export function useFitHeight(ref) {
  const lastHeight = useRef(0);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el || el.offsetHeight === lastHeight.current) return;
    lastHeight.current = el.offsetHeight;
    const dpr = window.devicePixelRatio;
    const width = Math.round(PANEL_WIDTH * dpr);
    const win = widget.tauriWindow;
    win
      .setSize(new PhysicalSize(width, Math.round(el.offsetHeight * dpr)))
      .then(() => keepOnMonitor(width))
      .catch(err => {
        lastHeight.current = 0; // retry on the next render
        console.error(err);
      });
  });
}

// The bar positions panels in its own pixel scale, which can differ from the
// panel's, so nudge the window back inside its monitor if it spills over.
// The edge margin matches the panel's actual gap below the bar.
async function keepOnMonitor(width) {
  const win = widget.tauriWindow;
  const [monitor, pos] = await Promise.all([currentMonitor(), win.outerPosition()]);
  if (!monitor) return;
  const barBottom = monitor.position.y + Math.round(BAR_HEIGHT * monitor.scaleFactor);
  const margin = Math.max(0, pos.y - barBottom);
  const minX = monitor.position.x + margin;
  const maxX = monitor.position.x + monitor.size.width - width - margin;
  // A panel this close to the right edge was pushed there by the bar's edge
  // clamp (it couldn't centre under its icon), so align it to the edge exactly.
  const snap = Math.round(32 * window.devicePixelRatio);
  const RIGHT_NUDGE = 2; // physical px; looked 2px short of the top gap
  const x = pos.x > maxX - snap ? maxX + RIGHT_NUDGE : Math.max(minX, pos.x);
  if (x !== pos.x) await win.setPosition(new PhysicalPosition(x, pos.y));
}

// Label/value grid; `two` lays the rows out in two column pairs.
export function Stats({ rows, two = false }) {
  return createElement(
    'div',
    { className: two ? 'stats two' : 'stats' },
    rows.map(([label, value]) =>
      createElement(
        Fragment,
        { key: label },
        createElement('span', { className: 'stat-label' }, label),
        createElement('span', { className: 'stat-value' }, value ?? '—'),
      ),
    ),
  );
}

// Runs `fetcher` (a PowerShell status call) one at a time and every `ms`
// after the previous run finishes, so slow scripts can't pile up. Without
// `ms` it only runs on refresh().
//
// Results reach onResult in request order: a result is dropped if a newer
// one has already landed. track(promise) feeds an action's result (e.g. a
// toggle that prints the new status) through the same ordering.
export function usePolling(fetcher, ms, onResult, onError = err => console.error(err)) {
  const state = useRef({ seq: 0, applied: 0, queue: Promise.resolve() }).current;
  const callbacks = useRef();
  callbacks.current = { fetcher, onResult, onError };

  function track(promise) {
    const id = ++state.seq;
    return promise.then(
      result => {
        if (id < state.applied) return;
        state.applied = id;
        callbacks.current.onResult(result);
      },
      err => callbacks.current.onError(err),
    );
  }

  // Queued behind any run in progress, so a refresh after an action always
  // reads the state after it.
  function refresh() {
    state.queue = state.queue.then(() => track(callbacks.current.fetcher()));
    return state.queue;
  }

  useEffect(() => {
    if (!ms) return;
    let timer;
    let alive = true;
    const loop = () => refresh().then(() => alive && (timer = setTimeout(loop, ms)));
    loop();
    return () => {
      alive = false;
      clearTimeout(timer);
    };
  }, [ms]);

  return { refresh, track };
}
