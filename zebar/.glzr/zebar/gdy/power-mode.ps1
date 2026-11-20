# Gets or sets the Windows 11 power mode (the Settings > Power slider).
# powercfg has no command for it. 'get' reads the registry; 'set' calls
# powrprof via compiled C#, so the DLL only loads when the user changes mode.
# Usage: power-mode.ps1 get
#        power-mode.ps1 set <efficiency|balanced|performance>
param(
    [Parameter(Mandatory)] [ValidateSet('get', 'set')] [string] $Action,
    [ValidateSet('efficiency', 'balanced', 'performance')] [string] $Mode
)

$ErrorActionPreference = 'Stop'

$modes = @{
    efficiency  = [guid]'961cc777-2547-4f9d-8174-7d86181b8a7a'
    balanced    = [guid]'00000000-0000-0000-0000-000000000000'
    performance = [guid]'ded574b5-45a0-4f42-8737-46345c09c238'
}

function Get-ModeName([guid] $overlay) {
    $name = $modes.Keys | Where-Object { $modes[$_] -eq $overlay }
    if ($name) { $name } else { $overlay.ToString() }
}

if ($Action -eq 'get') {
    # The overlay for the current power source (AC unless on battery).
    $onBattery = @(Get-CimInstance Win32_Battery | Where-Object BatteryStatus -eq 1).Count -gt 0
    $value = if ($onBattery) { 'ActiveOverlayDcPowerScheme' } else { 'ActiveOverlayAcPowerScheme' }
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes'
    $overlay = (Get-ItemProperty $key -Name $value -ErrorAction SilentlyContinue).$value
    # A missing value means the default (balanced) overlay.
    Get-ModeName $(if ($overlay) { $overlay } else { [guid]::Empty })
    return
}

if (-not $Mode) { throw 'set needs a mode' }

. "$PSScriptRoot\dll-cache.ps1"
Import-CachedType 'gdy-power-mode' @'
using System;
using System.Runtime.InteropServices;

namespace Gdy {
    public static class PowerMode {
        [DllImport("powrprof.dll")]
        public static extern uint PowerGetEffectiveOverlayScheme(out Guid overlay);
        [DllImport("powrprof.dll")]
        public static extern uint PowerSetActiveOverlayScheme(Guid overlay);
    }
}
'@

$rc = [Gdy.PowerMode]::PowerSetActiveOverlayScheme($modes[$Mode])
if ($rc -ne 0) { throw "PowerSetActiveOverlayScheme failed: $rc" }

$current = [guid]::Empty
$rc = [Gdy.PowerMode]::PowerGetEffectiveOverlayScheme([ref] $current)
if ($rc -ne 0) { throw "PowerGetEffectiveOverlayScheme failed: $rc" }
Get-ModeName $current
