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

$clusterName = 'NpwServer'
$clusterDir = "$dontStarveDir\$clusterName"

New-Item -ItemType Directory -Force -Path $clusterDir | Out-Null

if ($ClusterToken) {
    $ClusterToken | Out-File -Encoding ascii $clusterDir\cluster_token.txt
}

$cfg = Get-Content $clusterDir\cluster.ini -ErrorAction SilentlyContinue |
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

if (-not (Test-Path $clusterDir\Master\leveldataoverride.lua)) {

@"
return {
  desc="The standard Don't Starve experience.",
  hideminimap=false,
  id="SURVIVAL_TOGETHER",
  location="forest",
  max_playlist_position=999,
  min_playlist_position=0,
  name="Default",
  numrandom_set_pieces=5,
  override_level_string=false,
  overrides={
    alternatehunt="default",
    angrybees="default",
    autumn="default",
    bearger="default",
    beefalo="default",
    beefaloheat="default",
    bees="default",
    berrybush="default",
    birds="default",
    boons="default",
    branching="default",
    butterfly="default",
    buzzard="default",
    cactus="default",
    carrot="default",
    catcoon="default",
    chess="default",
    day="default",
    deciduousmonster="default",
    deerclops="default",
    dragonfly="default",
    flint="default",
    flowers="default",
    frograin="default",
    goosemoose="default",
    grass="default",
    houndmound="default",
    hounds="default",
    hunt="default",
    krampus="default",
    layout_mode="LinkNodesByKeys",
    liefs="default",
    lightning="default",
    lightninggoat="default",
    loop="default",
    lureplants="default",
    marshbush="default",
    merm="default",
    meteorshowers="default",
    meteorspawner="default",
    moles="default",
    mushroom="default",
    penguins="default",
    perd="default",
    pigs="default",
    ponds="default",
    prefabswaps="default",
    prefabswaps_start="default",
    rabbits="default",
    reeds="default",
    regrowth="default",
    roads="default",
    rock="default",
    rock_ice="default",
    sapling="default",
    season_start="default",
    spiders="default",
    spring="default",
    start_location="default",
    summer="default",
    tallbirds="default",
    task_set="default",
    tentacles="default",
    touchstone="default",
    trees="default",
    tumbleweed="default",
    walrus="default",
    weather="default",
    wildfires="default",
    winter="default",
    world_size="default",
    wormhole_prefab="wormhole" 
  },
  random_set_pieces={
    "Chessy_1",
    "Chessy_2",
    "Chessy_3",
    "Chessy_4",
    "Chessy_5",
    "Chessy_6",
    "ChessSpot1",
    "ChessSpot2",
    "ChessSpot3",
    "Maxwell1",
    "Maxwell2",
    "Maxwell3",
    "Maxwell4",
    "Maxwell5",
    "Maxwell6",
    "Maxwell7",
    "Warzone_1",
    "Warzone_2",
    "Warzone_3" 
  },
  required_prefabs={ "multiplayer_portal" },
  substitutes={  },
  version=2 
}
"@ | Out-File -Encoding ascii $clusterDir\Master\leveldataoverride.lua

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

if (-not (Test-Path $clusterDir\Caves\leveldataoverride.lua)) {

@"
return {
  background_node_range={ 0, 1 },
  desc="Delve into the caves... together!",
  hideminimap=false,
  id="DST_CAVE",
  location="cave",
  max_playlist_position=999,
  min_playlist_position=0,
  name="The Caves",
  numrandom_set_pieces=0,
  override_level_string=false,
  overrides={
    banana="default",
    bats="default",
    berrybush="default",
    boons="default",
    branching="default",
    bunnymen="default",
    cave_ponds="default",
    cave_spiders="default",
    cavelight="default",
    chess="default",
    earthquakes="default",
    fern="default",
    fissure="default",
    flint="default",
    flower_cave="default",
    grass="default",
    layout_mode="RestrictNodesByKey",
    lichen="default",
    liefs="default",
    loop="default",
    marshbush="default",
    monkey="default",
    mushroom="default",
    mushtree="default",
    prefabswaps="default",
    prefabswaps_start="default",
    reeds="default",
    regrowth="default",
    roads="never",
    rock="default",
    rocky="default",
    sapling="default",
    season_start="default",
    slurper="default",
    slurtles="default",
    start_location="caves",
    task_set="cave_default",
    tentacles="default",
    touchstone="default",
    trees="default",
    weather="default",
    world_size="default",
    wormhole_prefab="tentacle_pillar",
    wormlights="default",
    worms="default" 
  },
  required_prefabs={ "multiplayer_portal" },
  substitutes={  },
  version=2 
}
"@ | Out-File -Encoding ascii $clusterDir\Caves\leveldataoverride.lua

}

if (-not (Test-Path $clusterDir\Caves\worldgenoverride.lua)) {

@"
return {
override_enabled = true,
preset = "DST_CAVE",
}
"@ | Out-File -Encoding ascii $clusterDir\Caves\worldgenoverride.lua

}

if (-not (Test-Path $dontStarveDir\Start$clusterName.cmd)) {

@"
pushd %~dp0\bin

start dontstarve_dedicated_server_nullrenderer -cluster $clusterName -shard Master
start dontstarve_dedicated_server_nullrenderer -cluster $clusterName -shard Caves
"@ | Out-File -Encoding ascii $dontStarveDir\Start$clusterName.cmd

}

if ($AutoStart) {
    (New-Object -ComObject Shell.Application).NameSpace(0x07) | Out-Null
    $startupDir = [Environment]::GetFolderPath('Startup')
    if (-not (Test-Path $startupDir\DontStarveServer.lnk)) {
        New-Shortcut $startupDir\DontStarveServer.lnk $dontStarveDir\Start$clusterName.cmd
    }
}

}