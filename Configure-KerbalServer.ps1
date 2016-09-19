. $PSScriptRoot\Common.ps1

function Configure-KerbalServer {

#<#
#.Parameter KeepTickingWhileOffline
#    Specify if the the server universe 'ticks' while nobody is connected or the server is shut down.
#.Parameter SendPlayerToLatestSubspace
#    If true, sends the player to the latest subspace upon connecting. If false, sends the player to the previous subspace they were in.
#    NOTE: This may cause time-paradoxes, and will not work across server restarts.
#.Parameter Cheats
#    Enable use of cheats in-game.
#.Parameter MaxPlayers
#    Maximum amount of players that can join the server.
#.Parameter ServerMotd
#    Specify the server's MOTD (message of the day).
##>
param(
    [switch] $AutoStart,

    [ValidateSet('MCW_FORCE', 'MCW_VOTE', 'MCW_LOWEST', 'SUBSPACE_SIMPLE', 'SUBSPACE', 'NONE')]
    [string] $WarpMode,

    [ValidateSet('SANDBOX', 'SCIENCE', 'CAREER')]
    [string] $GameMode,

    [ValidateSet('EASY', 'NORMAL', 'MODERATE', 'HARD', 'CUSTOM')]
    [string] $GameDifficulty,

    [object] $Whitelisted,
    [object] $KeepTickingWhileOffline,
    [object] $SendPlayerToLatestSubspace,
    [object] $Cheats,
    [string] $ServerName,
    [int] $MaxPlayers,
    [string] $ServerMotd
)

if ($Whitelisted -ne $null) {
    $Whitelisted = [bool]$Whitelisted
}

if ($KeepTickingWhileOffline -ne $null) {
    $KeepTickingWhileOffline = [bool]$KeepTickingWhileOffline
}

if ($SendPlayerToLatestSubspace -ne $null) {
    $SendPlayerToLatestSubspace = [bool]$SendPlayerToLatestSubspace
}

if ($Cheats -ne $null) {
    $Cheats = [bool]$Cheats
}

$serverDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'KerbalServer'

New-Item -ItemType Directory -Force -Path $serverDir | Out-Null

if (-not (Test-Path $serverDir\server.zip)) {
    Get-WebFile http://godarklight.info.tm/dmp/build/release/DMPServer.zip $serverDir\server.zip -Sha256Checksum 363AD93BCE86464C5E0EE535E422BD427A833B047FFFF15452A6322A1022556B
    
    Expand-Archive -Path $serverDir\server.zip -DestinationPath $serverDir
    Move-Item $serverDir\DMPServer\* $serverDir
    Remove-Item $serverDir\DMPServer
}

$configDir = "$serverDir\Config"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

$cfg = Get-Content $configDir\Settings.txt -ErrorAction SilentlyContinue |
    foreach { $_ -replace '#.*','' } |
    where { $_ -match '\S.*=.*\S' } |
    Out-String |
    ConvertFrom-StringData

@"
address=::

port=6702

warpMode=$(Select-FirstValue $WarpMode $cfg.warpMode 'SUBSPACE')

gameMode=$(Select-FirstValue $GameMode $cfg.gameMode 'SANDBOX')

gameDifficulty=$(Select-FirstValue $GameDifficulty $cfg.gameDifficulty 'NORMAL')

whitelisted=$(Select-FirstValue -StrictNullCheck $Whitelisted $cfg.whitelisted $false)

# modControl - Enable mod control.
# # WARNING: Only consider turning off mod control for private servers.
# # The game will constantly complain about missing parts if there are missing mods.
#
# Valid values are:
#   DISABLED
#   ENABLED_STOP_INVALID_PART_SYNC
#   ENABLED_STOP_INVALID_PART_LAUNCH
modControl=ENABLED_STOP_INVALID_PART_SYNC

keepTickingWhileOffline=$(Select-FirstValue -StrictNullCheck $KeepTickingWhileOffline $cfg.keepTickingWhileOffline $true)

sendPlayerToLatestSubspace=$(Select-FirstValue -StrictNullCheck $SendPlayerToLatestSubspace $cfg.sendPlayerToLatestSubspace $true)

# useUTCTimeInLog - Use UTC instead of system time in the log.
useUTCTimeInLog=False

# logLevel - Minimum log level.
#
# Valid values are:
#   DEBUG
#   INFO
#   CHAT
#   ERROR
#   FATAL
logLevel=DEBUG

# screenshotsPerPlayer - Specify maximum number of screenshots to save per player. -1 = None, 0 = Unlimited
screenshotsPerPlayer=20

# screenshotHeight - Specify vertical resolution of screenshots.
screenshotHeight=720

cheats=$(Select-FirstValue -StrictNullCheck $Cheats $cfg.cheats $true)

# httpPort - HTTP port for server status. 0 = Disabled
httpPort=0

serverName=$(Select-FirstValue $ServerName $cfg.serverName 'DMP Server')

maxPlayers=$(Select-FirstValue $MaxPlayers 20)

# screenshotDirectory - Specify a custom screenshot directory.
# #This directory must exist in order to be used. Leave blank to store it in Universe.
screenshotDirectory=

# autoNuke - Specify in minutes how often /nukeksc automatically runs. 0 = Disabled
autoNuke=0

# autoDekessler - Specify in minutes how often /dekessler automatically runs. 0 = Disabled
autoDekessler=30

# numberOfAsteroids - How many untracked asteroids to spawn into the universe. 0 = Disabled
numberOfAsteroids=30

# consoleIdentifier - Specify the name that will appear when you send a message using the server's console.
consoleIdentifier=Server

serverMotd=$(Select-FirstValue $ServerMotd $cfg.serverMotd 'Welcome, %name%!')

# expireScreenshots - Specify the amount of days a screenshot should be considered as expired and deleted. 0 = Disabled
expireScreenshots=0

# compressionEnabled - Specify whether to enable compression. Decreases bandwidth usage but increases CPU usage. 0 = Disabled
compressionEnabled=True

# expireLogs - Specify the amount of days a log file should be considered as expired and deleted. 0 = Disabled
expireLogs=0

# safetyBubbleDistance - Specify the minimum distance in which vessels can interact with eachother at the launch pad and runway
safetyBubbleDistance=100
"@ | Out-File -Encoding ascii $configDir\Settings.txt

if ($AutoStart) {
    $startupDir = Get-StartupDir
    if (-not (Test-Path $startupDir\KerbalServer.lnk)) {
        New-Shortcut $startupDir\KerbalServer.lnk $serverDir\DMPServer.exe
    }
}

}