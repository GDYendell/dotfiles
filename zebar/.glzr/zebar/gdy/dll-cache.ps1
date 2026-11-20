# Dot-sourced by the helpers that P/Invoke through C#. Compiling takes ~1s,
# so each assembly is built once and cached.

# Loads the C# in $Source as a cached DLL in %LOCALAPPDATA%\gdy. That is the
# user's own folder, unlike the shared and predictable %TEMP%. The file name
# includes a hash of the source, so editing the C# rebuilds automatically.
function Import-CachedType([string] $Name, [string] $Source) {
    $dir = Join-Path $env:LOCALAPPDATA 'gdy'
    $null = New-Item -ItemType Directory -Force $dir
    $bytes = [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Source))
    $hash = -join ($bytes[0..5] | ForEach-Object { $_.ToString('x2') })
    $dll = Join-Path $dir "$Name-$hash.dll"
    if (-not (Test-Path $dll)) {
        # Build under a unique name and move it into place, so two panels
        # compiling at once can't load a half-written file.
        $build = Join-Path $dir "build-$PID"
        $null = New-Item -ItemType Directory -Force $build
        $tmp = Join-Path $build "$Name.dll"
        Add-Type -TypeDefinition $Source -OutputAssembly $tmp -OutputType Library
        try { Move-Item $tmp $dll -ErrorAction Stop } catch { } # another run won
        Remove-Item $build -Recurse -Force -ErrorAction SilentlyContinue
        # Old builds; ones still loaded elsewhere are left for next time.
        Get-ChildItem $dir -Filter "$Name-*.dll" | Where-Object FullName -ne $dll |
            Remove-Item -ErrorAction SilentlyContinue
    }
    Add-Type -Path $dll
}
