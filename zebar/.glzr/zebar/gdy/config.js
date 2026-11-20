// Sizes, thresholds and refresh rates shared by the bar and the panels.

export const PANEL_WIDTH = 400; // CSS px; panel.js passes it to panel.css as --panel-width
export const PANEL_TOP = 30; // CSS px from the screen top: bar height + GlazeWM top gap
export const BAR_HEIGHT = 26; // Zebar px; must match the bar preset height in zpack.json

// CPU/memory refresh, and how many samples the system panel graphs.
export const SYSTEM_REFRESH_MS = 2000;
export const HISTORY_LENGTH = 60;

// Usage percentages above these show as alerts.
export const CPU_ALERT = 85;
export const MEMORY_ALERT = 90;
export const isBatteryLow = bat => !bat.isCharging && bat.chargePercent <= 15;
