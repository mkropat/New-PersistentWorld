function ConvertTo-Lower {
    "$input".ToLower()
}

function Get-StartupDir {
    (New-Object -ComObject Shell.Application).NameSpace(0x07) | Out-Null
    [Environment]::GetFolderPath('Startup')
}

function Get-WebFile {
    param(
        [string] $Uri,
        [string] $Destination,
        [string] $Sha256Checksum
    )

    if (Test-Path -PathType Container $Destination) {
        $Destination = "$Destination\$(Split-Path -Leaf $Uri)"
    }

    Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile "$Destination.download"

    if ($Sha256Checksum) {
        $r = Get-FileHash -Algorithm SHA256 "$Destination.download"
        if ($r.Hash -ne $Sha256Checksum) {
            Remove-Item "$Destination.download"
            throw "Checksum verification failed on $(Split-Path -Leaf $Destination)"
        }
    }

    Move-Item "$Destination.download" $Destination
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
    param (
        [string] $Path,
        [object] $Target,
        [object] $WorkingDirectory,
        [string[]] $Arguments
    )

    if (-not $Path.EndsWith('.lnk')) {
        $Path = "$Path.lnk"
    }
    $Path = Resolve-NonExistentPath $Path

    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($Path)

    $Target = Get-Item $Target
    $shortcut.TargetPath = $Target.FullName

    if ($WorkingDirectory) {
         $shortcut.WorkingDirectory = Resolve-Path $WorkingDirectory | select -ExpandProperty Path
    }
    elseif ($Target.Directory)
    {
        $shortcut.WorkingDirectory = $Target.Directory.FullName
    }

    if ($Arguments) {
        $shortcut.Arguments = @($Arguments | foreach {
            if ($_ -like '* *') {
                """$_"""
            }
            else {
                $_
            }
        }) -join ' '
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
