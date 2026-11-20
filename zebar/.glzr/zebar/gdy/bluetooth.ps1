# Bluetooth helper for the Zebar bluetooth panel, via WinRT.
# Usage: bluetooth.ps1 status     -> JSON: radio state + paired devices
#        bluetooth.ps1 on|off     -> set the radio, then print status
param(
    [Parameter(Mandatory)] [ValidateSet('status', 'on', 'off')] [string] $Action
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Devices.Radios.Radio, Windows.System.Devices, ContentType = WindowsRuntime]
$null = [Windows.Devices.Enumeration.DeviceInformation, Windows.Devices.Enumeration, ContentType = WindowsRuntime]
$null = [Windows.Devices.Bluetooth.BluetoothDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime]
$null = [Windows.Devices.Bluetooth.BluetoothLEDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime]

# Blocks on a WinRT IAsyncOperation<T> and returns its result.
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1
function Await($operation, [type] $resultType) {
    $task = $asTask.MakeGenericMethod($resultType).Invoke($null, @($operation))
    $null = $task.Wait(-1)
    $task.Result
}

function Get-Radio {
    $null = Await ([Windows.Devices.Radios.Radio]::RequestAccessAsync()) ([Windows.Devices.Radios.RadioAccessStatus])
    $radios = Await ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) `
        ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
    $radios | Where-Object { $_.Kind -eq 'Bluetooth' } | Select-Object -First 1
}

# Paired classic and LE devices with their connection status. (Querying
# association endpoints instead takes ~60s and misreports connections.)
function Get-PairedDevices {
    $kinds = @(
        @{ type = [Windows.Devices.Bluetooth.BluetoothDevice]; protocol = 'classic' }
        @{ type = [Windows.Devices.Bluetooth.BluetoothLEDevice]; protocol = 'le' }
    )
    $devices = foreach ($kind in $kinds) {
        $selector = $kind.type::GetDeviceSelectorFromPairingState($true)
        $found = Await ([Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($selector)) `
            ([Windows.Devices.Enumeration.DeviceInformationCollection])
        foreach ($info in $found) {
            if (-not $info.Name) { continue }
            $device = Await ($kind.type::FromIdAsync($info.Id)) ($kind.type)
            [ordered]@{
                name      = $info.Name
                connected = $device -and [string] $device.ConnectionStatus -eq 'Connected'
                # Classic only: AudioVideo, Peripheral, Phone, Computer, ...
                class     = if ($kind.protocol -eq 'classic' -and $device) { [string] $device.ClassOfDevice.MajorClass } else { $null }
            }
        }
    }
    # The same device can pair over both protocols; keep one, connected first.
    $devices | Sort-Object { -not $_.connected }, { $_.name } |
        Group-Object { $_.name } | ForEach-Object { $_.Group[0] }
}

$radio = Get-Radio
if ($Action -in 'on', 'off') {
    if (-not $radio) { throw 'No Bluetooth radio' }
    $state = if ($Action -eq 'on') { 'On' } else { 'Off' }
    $result = Await ($radio.SetStateAsync($state)) ([Windows.Devices.Radios.RadioAccessStatus])
    if ($result -ne 'Allowed') { throw "SetStateAsync: $result" }
}

$radioState = if ($radio) { [string] $radio.State } else { $null }
[ordered]@{
    radio   = $radioState
    # Device lookups hang while the radio is off, so only list them when on.
    devices = @(if ($radioState -eq 'On') { Get-PairedDevices })
} | ConvertTo-Json -Depth 4 -Compress
