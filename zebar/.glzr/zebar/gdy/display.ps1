# Display helper for the Zebar display panel.
# Usage: display.ps1 status                 -> JSON: brightness, nightLight, monitors
#        display.ps1 brightness <0-100>     -> built-in panel brightness (WMI)
#        display.ps1 nightlight on|off
#        display.ps1 scale <key> <percent>  -> display scale of one monitor
param(
    [Parameter(Mandatory)] [ValidateSet('status', 'brightness', 'nightlight', 'scale')]
    [string] $Action,
    [string] $Arg1,
    [string] $Arg2
)

$ErrorActionPreference = 'Stop'

# Display scale goes through the undocumented DisplayConfig DPI calls
# (device info types -3/-4), as Settings does. Scale is stored relative to
# the monitor's recommended step.
$source = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class GdyDisplay {
    [StructLayout(LayoutKind.Sequential)] public struct LUID { public uint Low; public int High; }
    [StructLayout(LayoutKind.Sequential)] struct PathSource { public LUID AdapterId; public uint Id; public uint ModeIdx; public uint Status; }
    [StructLayout(LayoutKind.Sequential)] struct PathTarget {
        public LUID AdapterId; public uint Id; public uint ModeIdx; public int Tech; public int Rotation;
        public int Scaling; public uint RefreshNum; public uint RefreshDen; public int ScanLine;
        public int Available; public uint Status;
    }
    [StructLayout(LayoutKind.Sequential)] struct PathInfo { public PathSource Source; public PathTarget Target; public uint Flags; }
    [StructLayout(LayoutKind.Sequential)] struct Header { public int Type; public uint Size; public LUID AdapterId; public uint Id; }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct TargetName {
        public Header Header; public uint Flags; public int Tech; public ushort Mfr; public ushort Product;
        public uint Connector;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)] public string FriendlyName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DevicePath;
    }
    [StructLayout(LayoutKind.Sequential)] struct DpiGet { public Header Header; public int Min; public int Cur; public int Max; }
    [StructLayout(LayoutKind.Sequential)] struct DpiSet { public Header Header; public int Rel; }

    const uint QDC_ONLY_ACTIVE_PATHS = 2;
    [DllImport("user32.dll")] static extern int GetDisplayConfigBufferSizes(uint flags, out uint paths, out uint modes);
    [DllImport("user32.dll")] static extern int QueryDisplayConfig(uint flags, ref uint numPaths, [Out] PathInfo[] paths, ref uint numModes, IntPtr modes, IntPtr topology);
    [DllImport("user32.dll")] static extern int DisplayConfigGetDeviceInfo(ref TargetName info);
    [DllImport("user32.dll")] static extern int DisplayConfigGetDeviceInfo(ref DpiGet info);
    [DllImport("user32.dll")] static extern int DisplayConfigSetDeviceInfo(ref DpiSet info);

    static readonly int[] Steps = { 100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500 };

    public class Monitor {
        public string Key; public string Name; public int Scale; public int[] Scales;
        internal LUID AdapterId; internal uint SourceId; internal int Recommended;
    }

    static PathInfo[] Paths() {
        uint numPaths, numModes;
        int err = GetDisplayConfigBufferSizes(QDC_ONLY_ACTIVE_PATHS, out numPaths, out numModes);
        if (err != 0) throw new Exception("GetDisplayConfigBufferSizes failed: " + err);
        var paths = new PathInfo[numPaths];
        IntPtr modes = Marshal.AllocHGlobal((int)numModes * 64);
        try {
            err = QueryDisplayConfig(QDC_ONLY_ACTIVE_PATHS, ref numPaths, paths, ref numModes, modes, IntPtr.Zero);
            if (err != 0) throw new Exception("QueryDisplayConfig failed: " + err);
        } finally {
            Marshal.FreeHGlobal(modes);
        }
        Array.Resize(ref paths, (int)numPaths);
        return paths;
    }

    static bool IsInternal(int tech) {
        // LVDS, embedded DisplayPort, embedded UDI, or the "internal" flag.
        return tech == 6 || tech == 11 || tech == 13 || tech == unchecked((int)0x80000000);
    }

    public static List<Monitor> Monitors() {
        var result = new List<Monitor>();
        var seen = new HashSet<string>();
        foreach (var p in Paths()) {
            string key = (uint)p.Source.AdapterId.High + "_" + p.Source.AdapterId.Low + "_" + p.Source.Id;
            if (!seen.Add(key)) continue; // cloned outputs share a source

            var name = new TargetName();
            name.Header.Type = 2; // GET_TARGET_NAME
            name.Header.Size = (uint)Marshal.SizeOf(typeof(TargetName));
            name.Header.AdapterId = p.Target.AdapterId;
            name.Header.Id = p.Target.Id;
            DisplayConfigGetDeviceInfo(ref name);

            var dpi = new DpiGet();
            dpi.Header.Type = -3; // GET_DPI_SCALE
            dpi.Header.Size = (uint)Marshal.SizeOf(typeof(DpiGet));
            dpi.Header.AdapterId = p.Source.AdapterId;
            dpi.Header.Id = p.Source.Id;
            if (DisplayConfigGetDeviceInfo(ref dpi) != 0) continue;

            int rec = Math.Abs(dpi.Min);
            int maxIdx = Math.Min(Steps.Length - 1, rec + dpi.Max);
            int curIdx = Math.Max(0, Math.Min(maxIdx, rec + dpi.Cur));
            var scales = new int[maxIdx + 1];
            Array.Copy(Steps, scales, maxIdx + 1);

            string friendly = name.FriendlyName;
            if (string.IsNullOrEmpty(friendly) || IsInternal(name.Tech)) friendly = "Built-in display";

            result.Add(new Monitor {
                Key = key, Name = friendly, Scale = Steps[curIdx], Scales = scales,
                AdapterId = p.Source.AdapterId, SourceId = p.Source.Id, Recommended = rec,
            });
        }
        return result;
    }

    public static void SetScale(string key, int percent) {
        foreach (var m in Monitors()) {
            if (m.Key != key) continue;
            int idx = Array.IndexOf(m.Scales, percent);
            if (idx < 0) throw new Exception("Unsupported scale " + percent + "% for " + m.Name);
            var set = new DpiSet();
            set.Header.Type = -4; // SET_DPI_SCALE
            set.Header.Size = (uint)Marshal.SizeOf(typeof(DpiSet));
            set.Header.AdapterId = m.AdapterId;
            set.Header.Id = m.SourceId;
            set.Rel = idx - m.Recommended;
            int err = DisplayConfigSetDeviceInfo(ref set);
            if (err != 0) throw new Exception("DisplayConfigSetDeviceInfo failed: " + err);
            return;
        }
        throw new Exception("No monitor " + key);
    }
}
'@

. "$PSScriptRoot\dll-cache.ps1"
Import-CachedType 'gdy-display' $source

# Night light state lives in a CloudStore blob. Byte 18 is 0x15 when on and
# 0x13 when off; "on" also inserts 10 00 after the CB 01 00 header at 19-22.
# Bytes 10-14 are a varint timestamp that must increase for the change to
# be picked up.
$nightLightKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\' +
    'default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate'

function Get-NightLight {
    $data = (Get-ItemProperty $nightLightKey -ErrorAction SilentlyContinue).Data
    [bool] ($data -and $data[18] -eq 0x15)
}

function Set-NightLight([bool] $on) {
    [byte[]] $data = (Get-ItemProperty $nightLightKey).Data
    if ((Get-NightLight) -eq $on) { return }
    $list = [System.Collections.Generic.List[byte]]::new($data)
    if ($on) {
        $list.InsertRange(23, [byte[]] @(0x10, 0x00))
        $list[18] = 0x15
    } else {
        if ($list[23] -eq 0x10 -and $list[24] -eq 0x00) { $list.RemoveRange(23, 2) }
        $list[18] = 0x13
    }
    for ($i = 10; $i -lt 15; $i++) {
        if (($list[$i] -band 0x7f) -lt 0x7f) { $list[$i] = $list[$i] + 1; break }
        $list[$i] = $list[$i] -band 0x80
    }
    Set-ItemProperty $nightLightKey -Name Data -Value ([byte[]] $list.ToArray()) -Type Binary
}

function Get-Brightness {
    $b = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($b) { [int] $b.CurrentBrightness } else { $null }
}

switch ($Action) {
    'status' {
        [ordered]@{
            brightness = Get-Brightness
            nightLight = Get-NightLight
            monitors   = @([GdyDisplay]::Monitors() | ForEach-Object {
                [ordered]@{ key = $_.Key; name = $_.Name; scale = $_.Scale; scales = $_.Scales }
            })
        } | ConvertTo-Json -Compress -Depth 4
    }
    'brightness' {
        $value = [Math]::Max(0, [Math]::Min(100, [int] $Arg1))
        $methods = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods | Select-Object -First 1
        $null = Invoke-CimMethod -InputObject $methods -MethodName WmiSetBrightness -Arguments @{ Timeout = 0; Brightness = [byte] $value }
    }
    'nightlight' {
        Set-NightLight ($Arg1 -eq 'on')
    }
    'scale' {
        [GdyDisplay]::SetScale($Arg1, [int] $Arg2)
    }
}
