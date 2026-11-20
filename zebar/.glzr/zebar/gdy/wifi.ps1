# Wi-Fi helper for the Zebar network panel. Wraps netsh (English output).
# Usage: wifi.ps1 status             -> JSON: interface + visible networks
#        wifi.ps1 connect <hex>      -> connect to a saved profile; the name
#                                       is UTF-8 hex so it is one token
#        wifi.ps1 disconnect
param(
    [Parameter(Mandatory)] [ValidateSet('status', 'connect', 'disconnect')] [string] $Action,
    [string] $ProfileHex
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# Splits "    Key     : value" lines into key/value pairs.
function Split-Field([string] $line) {
    if ($line -match '^\s*([^:]+?)\s*:\s*(.*?)\s*$') { return $Matches[1], $Matches[2] }
    return $null, $null
}

function Get-Interface {
    $info = @{}
    foreach ($line in netsh wlan show interfaces) {
        $key, $value = Split-Field $line
        if ($key -and -not $info.ContainsKey($key)) { $info[$key] = $value }
    }
    [ordered]@{
        state     = $info['State']
        ssid      = $info['SSID']
        band      = $info['Band']
        channel   = $info['Channel']
        radio     = $info['Radio type']
        auth      = $info['Authentication']
        signal    = if ($info['Signal']) { [int]($info['Signal'] -replace '\D') } else { $null }
        rxMbps    = $info['Receive rate (Mbps)']
        txMbps    = $info['Transmit rate (Mbps)']
    }
}

function Get-KnownProfiles {
    $names = @{}
    foreach ($line in netsh wlan show profiles) {
        if ($line -match 'All User Profile\s*:\s*(.+?)\s*$') { $names[$Matches[1]] = $true }
    }
    $names
}

# One entry per SSID, using its strongest BSSID.
function Get-Networks($known, $connectedSsid) {
    $networks = [ordered]@{}
    $current = $null
    foreach ($line in netsh wlan show networks mode=bssid) {
        if ($line -match '^SSID \d+ : (.*?)\s*$') {
            $ssid = $Matches[1]
            $current = if ($ssid) {
                if (-not $networks.Contains($ssid)) {
                    $networks[$ssid] = [ordered]@{
                        ssid = $ssid; signal = 0; auth = $null; bands = @()
                        known = $known.ContainsKey($ssid); connected = ($ssid -eq $connectedSsid)
                    }
                }
                $networks[$ssid]
            } else { $null } # hidden network
            continue
        }
        if (-not $current) { continue }
        $key, $value = Split-Field $line
        switch ($key) {
            'Authentication' { $current.auth = $value }
            'Signal' { $current.signal = [Math]::Max($current.signal, [int]($value -replace '\D')) }
            'Band' { if ($current.bands -notcontains $value) { $current.bands += $value } }
        }
    }
    @($networks.Values | Sort-Object { -not $_.connected }, { -$_.signal })
}

switch ($Action) {
    'status' {
        $iface = Get-Interface
        $connectedSsid = if ($iface.state -eq 'connected') { $iface.ssid } else { $null }
        [ordered]@{
            interface = $iface
            networks  = Get-Networks (Get-KnownProfiles) $connectedSsid
        } | ConvertTo-Json -Depth 4 -Compress
    }
    'connect' {
        if (-not $ProfileHex) { throw 'connect needs a profile name' }
        $bytes = [byte[]] ($ProfileHex -split '(..)' -ne '' | ForEach-Object { [Convert]::ToByte($_, 16) })
        $name = [Text.Encoding]::UTF8.GetString($bytes)
        netsh wlan connect "name=$name" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "netsh connect failed for '$name'" }
    }
    'disconnect' {
        netsh wlan disconnect | Out-Null
    }
}
