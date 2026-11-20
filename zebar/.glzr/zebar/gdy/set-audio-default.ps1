# Sets the default Windows audio endpoint (all roles) by its MMDevice ID,
# e.g. {0.0.0.00000000}.{guid}. Uses the undocumented IPolicyConfig COM
# interface, as there is no built-in cmdlet for this.
# Usage: set-audio-default.ps1 <device-id>
param(
    [Parameter(Mandatory)] [string] $DeviceId
)

$ErrorActionPreference = 'Stop'

$source = @'
using System;
using System.Runtime.InteropServices;

[ComImport, Guid("f8679f50-850a-41cf-9c72-430f290290c8"),
 InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IPolicyConfig {
    // Unused vtable slots; only their count and order matter.
    int GetMixFormat(); int GetDeviceFormat(); int ResetDeviceFormat();
    int SetDeviceFormat(); int GetProcessingPeriod(); int SetProcessingPeriod();
    int GetShareMode(); int SetShareMode(); int GetPropertyValue();
    int SetPropertyValue();
    [PreserveSig]
    int SetDefaultEndpoint([MarshalAs(UnmanagedType.LPWStr)] string id, int role);
}

[ComImport, Guid("870af99c-171d-4f9e-af0d-e63df40c2bc9")]
class CPolicyConfigClient { }

public static class GdyAudioPolicy {
    public static void SetDefault(string id) {
        var config = (IPolicyConfig)new CPolicyConfigClient();
        // Roles: console, multimedia, communications.
        for (int role = 0; role < 3; role++) {
            Marshal.ThrowExceptionForHR(config.SetDefaultEndpoint(id, role));
        }
    }
}
'@

. "$PSScriptRoot\dll-cache.ps1"
Import-CachedType 'gdy-audio-policy' $source

[GdyAudioPolicy]::SetDefault($DeviceId)
