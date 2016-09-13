. $PSScriptRoot\Common.ps1

function Configure-DontStarveServer {

param (
    [switch] $AutoStart,

    [string] $ClusterToken,

    [ValidateSet('survival', 'endless', 'wilderness')]
    [string] $GameMode,

    [int] $MaxPlayers,
    [object] $Pvp,
    [object] $PauseWhenEmpty,
    [string] $ServerDescription,
    [string] $ServerName,

    [ValidateSet('cooperative', 'competitive', 'social', 'madness')]
    [string] $ServerIntention,

    [string] $ServerPassword
)

if ($Pvp -ne $null) {
    $Pvp = [bool]$Pvp
}

if ($PauseWhenEmpty -ne $null) {
    $PauseWhenEmpty = [bool]$PauseWhenEmpty
}

$dontStarveDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Klei\DoNotStarveTogether'

New-Item -ItemType Directory -Force -Path $dontStarveDir | Out-Null

$steamDir = "$dontStarveDir\steam"
if (-not (Test-Path $steamDir\steamcmd.exe)) {
    New-Item -ItemType Directory -Force -Path $steamDir | Out-Null
    if (-not (Test-Path $steamDir\steamcmd.zip)) {
        Invoke-WebRequest -UseBasicParsing https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip -OutFile $steamDir\steamcmd.zip
    }

    Expand-Archive -Path $steamDir\steamcmd.zip -DestinationPath $steamDir
}

$steamMarkerFile = Get-Item $steamDir\appcache\packageinfo.vdf -ErrorAction SilentlyContinue
if ((-not $steamMarkerFile) -or ((Get-Date) - $steamMarkerFile.LastWriteTime).Hours -gt 0) {
    Write-Verbose 'Checking for updated game files...'
    & $steamDir\steamcmd.exe `
        +login anonymous `
        +force_install_dir $dontStarveDir `
        +app_update 343050 validate `
        +quit
}

$clusterDir = "$dontStarveDir\MyDediServer"

New-Item -ItemType Directory -Force -Path $clusterDir | Out-Null

if ($ClusterToken) {
    $ClusterToken | Out-File -Encoding ascii $clusterDir\cluster_token.txt
}

$cfg = Get-Content $clusterDir\cluster.ini |
    foreach { $_ -replace '(?<!\\);.*','' } |
    where { $_ -match '\S.*=.*\S' } |
    Out-String |
    ConvertFrom-StringData

@"
[GAMEPLAY]
game_mode = $(Select-FirstValue $GameMode $cfg.game_mode 'survival')
max_players = $(Select-FirstValue $MaxPlayers $cfg.max_players 6)
pvp = $(Select-FirstValue -StrictNullCheck $Pvp $cfg.pvp | ConvertTo-Lower)
pause_when_empty = $(Select-FirstValue -StrictNullCheck $PauseWhenEmpty $cfg.pause_when_empty | ConvertTo-Lower)

[NETWORK]
cluster_description = $(Select-FirstValue $ServerDescription $cfg.cluster_description 'This server is super duper!')
cluster_name = $(Select-FirstValue $ServerName $cfg.cluster_name 'Super Server') 
cluster_intention = $(Select-FirstValue $ServerIntention $cfg.cluster_intention 'cooperative')
cluster_password = $(Select-FirstValue $ServerPassword $cfg.cluster_password)

[MISC]
console_enabled = true

[SHARD]
shard_enabled = true
bind_ip = 127.0.0.1
master_ip = 127.0.0.1
master_port = 10889
cluster_key = $(Get-Random)
"@ | Out-File -Encoding ascii $clusterDir\cluster.ini

New-Item -ItemType Directory -Force -Path $clusterDir\Master | Out-Null

if (-not (Test-Path $clusterDir\Master\server.ini)) {

@"
[NETWORK]
server_port = 11000

[SHARD]
is_master = true

[STEAM]
master_server_port = 27018
authentication_port = 8768
"@ | Out-File -Encoding ascii $clusterDir\Master\server.ini

}

New-Item -ItemType Directory -Force -Path $clusterDir\Caves | Out-Null

if (-not (Test-Path $clusterDir\Caves\server.ini)) {

@"
[NETWORK]
server_port = 11001

[SHARD]
is_master = false
name = Caves

[STEAM]
master_server_port = 27019
authentication_port = 8769
"@ | Out-File -Encoding ascii $clusterDir\Caves\server.ini

}

if (-not (Test-Path $clusterDir\Caves\worldgenoverride.lua)) {

@"
return {
override_enabled = true,
preset = "DST_CAVE",
}
"@ | Out-File -Encoding ascii $clusterDir\Caves\worldgenoverride.lua

}

if (-not (Test-Path $dontStarveDir\DontStarveServer.cmd)) {

@"
pushd %~dp0\bin

start dontstarve_dedicated_server_nullrenderer -cluster MyDediServer -shard Master
start dontstarve_dedicated_server_nullrenderer -cluster MyDediServer -shard Caves
"@ | Out-File -Encoding ascii $dontStarveDir\DontStarveServer.cmd

}

if ($AutoStart) {
    (New-Object -ComObject Shell.Application).NameSpace(0x07) | Out-Null
    $startupDir = [Environment]::GetFolderPath('Startup')
    if (-not (Test-Path $startupDir\DontStarveServer.lnk)) {
        New-Shortcut $startupDir\DontStarveServer.lnk $dontStarveDir\DontStarveServer.cmd
    }
}

}