. $PSScriptRoot\Common.ps1

function Configure-MinecraftServer {

param(
    [switch] $AutoStart,
    [switch] $AcceptEula,

    [ValidateSet('Peaceful', 'Easy', 'Normal', 'Hard')]
    [string] $Difficulty,

    [ValidateSet('Survival', 'Creative', 'Adventure', 'Spectator')]
    [string] $GameMode,
    
    [ValidateSet('DEFAULT', 'FLAT', 'LARGEBIOMES', 'AMPLIFIED', 'CUSTOMIZED')]
    [string] $LevelType,

    [int] $MaxPlayers,
    [object] $Pvp,
    [string] $ServerMotd
)

if ($Pvp -ne $null) {
    $Pvp = [bool]$Pvp
}

$java = Get-Command javaw -ErrorAction SilentlyContinue
if (-not $java) {
    Write-Host -ForegroundColor Red 'Error: Java not found'
    Write-Host 'Try installing Chocolatey (https://chocolatey.org/) and then run: ' -NoNewline
    Write-Host -ForegroundColor Yellow 'cinst -y javaruntime'
    exit 1
}

$documentsDir = [Environment]::GetFolderPath('MyDocuments')

$serverDir = "$documentsDir\MinecraftServer"

New-Item -ItemType Directory -Force -Path $serverDir | Out-Null

$eulaCfg = Get-Content $serverDir\eula.txt -ErrorAction SilentlyContinue |
    foreach { $_ -replace '#.*','' } |
    where { $_ -match '\S.*=.*\S' } |
    Out-String |
    ConvertFrom-StringData

if (-not $AcceptEula -and $eulaCfg.eula -ne 'true') {
    Write-Host -ForegroundColor Red 'Error: you have not accepted the EULA: https://account.mojang.com/documents/minecraft_eula'
    Write-Host -ForegroundColor Red 'Try passing -AcceptEula'
    exit 1
}
if ($AcceptEula -and $eulaCfg.eula -ne 'true') {

@'
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula).
eula=true
'@ | Out-File -Encoding ascii $serverDir\eula.txt

}

if (-not (Test-Path $serverDir\minecraft_server.jar)) {
    Write-Verbose 'Downloading server software...'
    $downloadPageHtml = Invoke-WebRequest -UseBasicParsing https://minecraft.net/en/download/server | select -ExpandProperty Content
    if ($downloadPageHtml -notmatch '<a[^>]*href="([^"]*minecraft_server[^"]*\.jar)">') {
        throw 'Error: unable to locate server download'
    }
    $downloadUrl = $Matches[1]

    Get-WebFile $downloadUrl $serverDir\minecraft_server.jar -Sha256Checksum 195F468227C5F9218F3919538B9B16BA34ADCED67FC7D7B652C508A5E8D07A21
}

if (-not (Test-Path $serverDir\server.properties)) {

@"
generator-settings=
op-permission-level=4
allow-nether=true
level-name=world
enable-query=false
allow-flight=false
announce-player-achievements=true
server-port=25565
max-world-size=29999984
level-type=DEFAULT
enable-rcon=false
force-gamemode=false
level-seed=
server-ip=
network-compression-threshold=256
max-build-height=256
spawn-npcs=true
white-list=false
spawn-animals=true
snooper-enabled=true
hardcore=false
resource-pack-sha1=
online-mode=true
resource-pack=
pvp=true
difficulty=1
enable-command-block=false
player-idle-timeout=0
gamemode=0
max-players=20
max-tick-time=60000
spawn-monsters=true
view-distance=10
generate-structures=true
motd=A Minecraft Server
"@ | Out-File -Encoding ascii $serverDir\server.properties

}

$cfg = Get-Content $serverDir\server.properties -ErrorAction SilentlyContinue |
    foreach { $_ -replace '#.*','' } |
    where { $_ -match '\S.*=.*\S' } |
    Out-String |
    ConvertFrom-StringData

$difficultyMapping = @{
    Peaceful = 0
    Easy = 1
    Normal = 2
    Hard = 3
}
if ($Difficulty) {
    $cfg.difficulty = $difficultyMapping[$Difficulty]
}

$gameModeMapping = @{
    Survival = 0
    Creative = 1
    Adventure = 2
    Spectator = 3
}
if ($GameMode) {
    $cfg.gamemode = $gameModeMapping[$GameMode]
}

if ($LevelType) {
    $cfg.'level-type' = $LevelType
}

if ($MaxPlayers) {
    $cfg.'max-players' = $MaxPlayers
}

if ($Pvp -ne $null) {
    $cfg.pvp = $Pvp | ConvertTo-Lower
}

if ($ServerMotd) {
    $cfg.motd = $ServerMotd
}

$cfg.GetEnumerator() |
    sort -Property Name |
    foreach { "$($_.Name)=$($_.Value)" } |
    Out-File -Encoding ascii $serverDir\server.properties

if (-not (Get-NetFirewallRule | where { $_.DisplayName -eq 'MinecraftServer' })) {
    Write-Verbose 'Adding firewall exception...'
    New-NetFirewallRule -DisplayName 'MinecraftServer' -Action Allow -Direction Inbound -Protocol TCP -LocalPort 25565 | Out-Null
}

$linkArgs = @('-Xmx1024M', '-Xmx1024M', '-jar', "$serverDir\minecraft_server.jar")

if (-not (Test-Path $serverDir\RunServer.lnk)) {
    Write-Verbose 'Creating RunServer shortcut...'
    New-Shortcut $serverDir\RunServer.lnk $java.Path -WorkingDirectory $serverDir -Arguments $linkArgs
}

if ($AutoStart) {
    $startupDir = Get-StartupDir
    if (-not (Test-Path $startupDir\MinecraftServer.lnk)) {
        Write-Verbose 'Configuring Minecraft to run on login...'
        New-Shortcut $startupDir\MinecraftServer.lnk $java.Path -WorkingDirectory $serverDir -Arguments $linkArgs
    }
}

}