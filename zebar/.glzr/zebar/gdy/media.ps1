# Media helper for the Zebar media panel: what Zebar's media provider lacks
# (album art, source app, seeking), via the Windows media session API.
# Usage: media.ps1 info           -> JSON: source, art (data URI), position, end
#        media.ps1 seek <seconds> -> seek the current session
param(
    [Parameter(Mandatory)] [ValidateSet('info', 'seek')] [string] $Action,
    [int] $Seconds
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.IRandomAccessStreamWithContentType, Windows.Storage.Streams, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.DataReader, Windows.Storage.Streams, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.IContentTypeProvider, Windows.Storage.Streams, ContentType = WindowsRuntime]

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

$manager = Await ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) `
    ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])
$session = $manager.GetCurrentSession()

if ($Action -eq 'seek') {
    if (-not $session) { throw 'No media session' }
    $ok = Await ($session.TryChangePlaybackPositionAsync([long] $Seconds * 10000000)) ([bool])
    if (-not $ok) { throw 'Seek not supported by this source' }
    return
}

if (-not $session) { '{}'; return }

function Get-ArtDataUri($props) {
    if (-not $props.Thumbnail) { return $null }
    $stream = Await ($props.Thumbnail.OpenReadAsync()) ([Windows.Storage.Streams.IRandomAccessStreamWithContentType])
    # Read via the interfaces: PowerShell 5.1 can't see members of these
    # WinRT objects directly.
    $size = [uint32] [Windows.Storage.Streams.IRandomAccessStream].GetProperty('Size').GetValue($stream)
    if ($size -eq 0) { return $null }
    $type = [Windows.Storage.Streams.IContentTypeProvider].GetProperty('ContentType').GetValue($stream)
    $reader = [Windows.Storage.Streams.DataReader].GetConstructor(
        [type[]] @([Windows.Storage.Streams.IInputStream])).Invoke(@($stream))
    $null = Await ($reader.LoadAsync($size)) ([uint32])
    $bytes = New-Object byte[] $size
    $reader.ReadBytes($bytes)
    if (-not $type) { $type = 'image/png' }
    "data:$type;base64,$([Convert]::ToBase64String($bytes))"
}

$props = Await ($session.TryGetMediaPropertiesAsync()) `
    ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
$timeline = $session.GetTimelineProperties()

[ordered]@{
    source   = $session.SourceAppUserModelId
    art      = Get-ArtDataUri $props
    position = $timeline.Position.TotalSeconds
    end      = $timeline.EndTime.TotalSeconds
    canSeek  = $session.GetPlaybackInfo().Controls.IsPlaybackPositionEnabled
} | ConvertTo-Json -Compress
