function ConvertTo-Lower {
    "$input".ToLower()
}


if (-not (Get-Command Expand-Archive -ErrorAction SilentlyContinue)) {
    function Expand-Archive {
        param($Path, $DestinationPath)

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path $Path), (Resolve-Path $DestinationPath))
    }
}

function New-Shortcut
{
    # Adapted from a post by CB (http://stackoverflow.com/a/9701907/27581)
    param ( [string]$Path, $Target )

    if (-not $Path.EndsWith('.lnk')) {
        $Path = "$Path.lnk"
    }
    $Path = Resolve-NonExistentPath $Path

    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($Path)

    $Target = Get-Item $Target
    $shortcut.TargetPath = $Target.FullName

    if ($Target.Directory)
    {
        $shortcut.WorkingDirectory = $Target.Directory.FullName
    }

    $shortcut.Save()
}

function Resolve-NonExistentPath($Path) {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Select-FirstValue {
    param ([switch] $StrictNullCheck)

    $args |
        foreach { if ($_ -is [scriptblock]) { & $_ } else { $_ } } |
        where {
            if ($StrictNullCheck) {
                $_ -ne $null
            }
            else {
                $_
            }
        } |
        select -First 1
}
