// Nerd Font icon choices shared by the bar and the panels, so each panel's
// header shows the same icon as the bar button that opens it.
//
// The React URL must match the pages exactly so they share one React.
import { createElement } from 'https://esm.sh/react@18.3.1?dev';

export function Icon({ name, className = '', ...props }) {
  return createElement('i', { className: `nf ${name} ${className}`, ...props });
}

export const DISPLAY_ICON = 'nf-md-monitor';
export const BLUETOOTH_ICON = 'nf-md-bluetooth';
export const SYSTEM_ICON = 'nf-oct-cpu';

export function wifiIcon(signal) {
  if (signal == null) return 'nf-md-wifi_strength_off_outline';
  if (signal >= 80) return 'nf-md-wifi_strength_4';
  if (signal >= 60) return 'nf-md-wifi_strength_3';
  if (signal >= 40) return 'nf-md-wifi_strength_2';
  if (signal >= 20) return 'nf-md-wifi_strength_1';
  return 'nf-md-wifi_strength_outline';
}

// From Zebar's network provider output.
export function networkIcon(net) {
  switch (net?.defaultInterface?.type) {
    case 'ethernet':
      return 'nf-md-ethernet';
    case 'proprietary_virtual':
      return 'nf-md-shield_lock_outline';
    case 'wifi':
      return wifiIcon(net.defaultGateway?.signalStrength ?? 0);
    default:
      return wifiIcon(null);
  }
}

// From an audio provider device.
export function volumeIcon(dev) {
  if (!dev || dev.isMuted || dev.volume === 0) return 'nf-md-volume_off';
  if (dev.volume < 34) return 'nf-md-volume_low';
  if (dev.volume < 67) return 'nf-md-volume_medium';
  return 'nf-md-volume_high';
}

// From Zebar's battery provider output.
export function batteryIcon(bat) {
  const level = Math.min(10, Math.round(bat.chargePercent / 10)) * 10;
  if (bat.isCharging) {
    return level === 0 ? 'nf-md-battery_charging_outline' : `nf-md-battery_charging_${level}`;
  }
  if (level === 100) return 'nf-md-battery';
  if (level === 0) return 'nf-md-battery_outline';
  return `nf-md-battery_${level}`;
}

// Zebar weather provider status -> icon.
const WEATHER_ICONS = {
  clear_day: 'nf-weather-day_sunny',
  clear_night: 'nf-weather-night_clear',
  cloudy_day: 'nf-weather-day_cloudy',
  cloudy_night: 'nf-weather-night_alt_cloudy',
  light_rain_day: 'nf-weather-day_sprinkle',
  light_rain_night: 'nf-weather-night_alt_sprinkle',
  heavy_rain_day: 'nf-weather-day_rain',
  heavy_rain_night: 'nf-weather-night_alt_rain',
  snow_day: 'nf-weather-day_snow',
  snow_night: 'nf-weather-night_alt_snow',
  thunder_day: 'nf-weather-day_lightning',
  thunder_night: 'nf-weather-night_alt_lightning',
};

export const weatherIcon = weather => WEATHER_ICONS[weather?.status] ?? 'nf-weather-cloud';
