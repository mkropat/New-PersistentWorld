. $PSScriptRoot\Common.ps1

function Configure-TerrariaServer {

param(
    [switch] $AutoStart,
    [string] $AutoStartWorldPath,

    [string] $ServerName,
    [string] $ServerPassword,
    [int] $MaxPlayers
)

$documentsDir = [Environment]::GetFolderPath('MyDocuments')

$serverDir = "$documentsDir\TerrariaServer"

New-Item -ItemType Directory -Force -Path $serverDir | Out-Null

if (-not (Test-Path $serverDir\server.zip)) {
    Write-Verbose 'Server software not found. Downloading it...'

    $releaseUrl = Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/NyxStudios/TShock/releases/latest |
        ConvertFrom-Json |
        select -ExpandProperty assets |
        select -ExpandProperty browser_download_url -First 1
    Get-WebFile $releaseUrl $serverDir\server.zip -Sha256Checksum 1BBD1E1EE3312A8BF79844435FFBCBBE256CBC3D89929291E0BE926E749624F1

    Expand-Archive -Path $serverDir\server.zip -DestinationPath $serverDir
}

if (-not (Test-Path "$serverDir\tshock\config.json")) {

@"
{
  "InvasionMultiplier": 1,
  "DefaultMaximumSpawns": 5,
  "DefaultSpawnRate": 600,
  "ServerPort": 7777,
  "EnableWhitelist": false,
  "InfiniteInvasion": false,
  "PvPMode": "normal",
  "SpawnProtection": true,
  "SpawnProtectionRadius": 10,
  "MaxSlots": 8,
  "RangeChecks": true,
  "DisableBuild": false,
  "SuperAdminChatRGB": [
    255,
    0,
    0
  ],
  "SuperAdminChatPrefix": "(Admin) ",
  "SuperAdminChatSuffix": "",
  "BackupInterval": 0,
  "BackupKeepFor": 60,
  "RememberLeavePos": false,
  "HardcoreOnly": false,
  "MediumcoreOnly": false,
  "KickOnMediumcoreDeath": false,
  "BanOnMediumcoreDeath": false,
  "AutoSave": true,
  "AnnounceSave": true,
  "MaximumLoginAttempts": 3,
  "ServerName": "",
  "UseServerName": false,
  "MasterServer": "127.0.0.1",
  "StorageType": "sqlite",
  "MySqlHost": "localhost:3306",
  "MySqlDbName": "",
  "MySqlUsername": "",
  "MySqlPassword": "",
  "MediumcoreBanReason": "Death results in a ban",
  "MediumcoreKickReason": "Death results in a kick",
  "EnableDNSHostResolution": false,
  "EnableIPBans": true,
  "EnableUUIDBans": true,
  "EnableBanOnUsernames": false,
  "DefaultRegistrationGroupName": "default",
  "DefaultGuestGroupName": "guest",
  "DisableSpewLogs": true,
  "DisableSecondUpdateLogs": false,
  "HashAlgorithm": "sha512",
  "BufferPackets": true,
  "ServerFullReason": "Server is full",
  "WhitelistKickReason": "You are not on the whitelist.",
  "ServerFullNoReservedReason": "Server is full. No reserved slots open.",
  "SaveWorldOnCrash": true,
  "EnableGeoIP": false,
  "EnableTokenEndpointAuthentication": false,
  "RestApiEnabled": false,
  "RestApiPort": 7878,
  "DisableTombstones": true,
  "DisplayIPToAdmins": false,
  "KickProxyUsers": true,
  "DisableHardmode": false,
  "DisableDungeonGuardian": false,
  "DisableClownBombs": false,
  "DisableSnowBalls": false,
  "ChatFormat": "{1}{2}{3}: {4}",
  "ChatAboveHeadsFormat": "{2}",
  "ForceTime": "normal",
  "TileKillThreshold": 60,
  "TilePlaceThreshold": 20,
  "TileLiquidThreshold": 15,
  "ProjectileThreshold": 50,
  "ProjIgnoreShrapnel": true,
  "RequireLogin": false,
  "DisableInvisPvP": false,
  "MaxRangeForDisabled": 10,
  "ServerPassword": "",
  "RegionProtectChests": false,
  "RegionProtectGemLocks": true,
  "DisableLoginBeforeJoin": false,
  "DisableUUIDLogin": false,
  "KickEmptyUUID": false,
  "AllowRegisterAnyUsername": false,
  "AllowLoginAnyUsername": true,
  "MaxDamage": 1175,
  "MaxProjDamage": 1175,
  "KickOnDamageThresholdBroken": false,
  "IgnoreProjUpdate": false,
  "IgnoreProjKill": false,
  "IgnoreNoClip": false,
  "AllowIce": false,
  "AllowCrimsonCreep": true,
  "AllowCorruptionCreep": true,
  "AllowHallowCreep": true,
  "StatueSpawn200": 3,
  "StatueSpawn600": 6,
  "StatueSpawnWorld": 10,
  "PreventBannedItemSpawn": false,
  "PreventDeadModification": true,
  "EnableChatAboveHeads": false,
  "ForceXmas": false,
  "AllowAllowedGroupsToSpawnBannedItems": false,
  "IgnoreChestStacksOnLoad": false,
  "LogPath": "tshock",
  "UseSqlLogs": false,
  "RevertToTextLogsOnSqlFailures": 10,
  "PreventInvalidPlaceStyle": true,
  "BroadcastRGB": [
    127,
    255,
    212
  ],
  "RestUseNewPermissionModel": true,
  "ApplicationRestTokens": {},
  "ReservedSlots": 20,
  "LogRest": false,
  "RespawnSeconds": 5,
  "RespawnBossSeconds": 10,
  "TilePaintThreshold": 15,
  "EnableMaxBytesInBuffer": false,
  "MaxBytesInBuffer": 5242880,
  "ForceHalloween": false,
  "AllowCutTilesAndBreakables": false,
  "CommandSpecifier": "/",
  "CommandSilentSpecifier": ".",
  "KickOnHardcoreDeath": false,
  "BanOnHardcoreDeath": false,
  "HardcoreBanReason": "Death results in a ban",
  "HardcoreKickReason": "Death results in a kick",
  "AnonymousBossInvasions": true,
  "MaxHP": 500,
  "MaxMP": 200,
  "SaveWorldOnLastPlayerExit": true,
  "BCryptWorkFactor": 7,
  "MinimumPasswordLength": 4,
  "RESTMaximumRequestsPerInterval": 5,
  "RESTRequestBucketDecreaseIntervalMinutes": 1,
  "RESTLimitOnlyFailedLoginRequests": true,
  "ShowBackupAutosaveMessages": true
}
"@ | Out-File -Encoding ascii "$serverDir\tshock\config.json"

}

$cfg = Get-Content -ErrorAction SilentlyContinue "$serverDir\tshock\config.json" |
    Out-String |
    ConvertFrom-Json

if (-not $cfg) {
    $cfg = @{}
}

if ($ServerName) {
    $cfg.ServerName = $ServerName
}
if ($ServerPassword) {
    $cfg.ServerPassword = $ServerPassword
}
if ($MaxPlayers) {
    $cfg.MaxSlots = $MaxPlayers
}

$cfg | ConvertTo-Json -Depth 32 | Out-File -Encoding ascii "$serverDir\tshock\config.json"

if ($AutoStart) {
    Write-Verbose 'Configuring Terraria to run on login...'

    $args = @()

    if ($AutoStartWorldPath) {
        $args = @('-world', $AutoStartWorldPath)
    }
    else {
        $worldsDir = "$documentsDir\My Games\Terraria\Worlds"
        $worldFiles = Get-Item "$worldsDir\*.wld"
        if (@($worldFiles).Count -eq 1) {
            $args = @('-world', $worldFiles.FullName)
        }
    }

    $startupDir = Get-StartupDir
    New-Shortcut $startupDir\TerrariaServer.lnk $serverDir\TerrariaServer.exe -Arguments $args

    Write-Host 'Statup link created in ' -NoNewline
    Write-Host -ForegroundColor Green 'shell:startup'
}

}
