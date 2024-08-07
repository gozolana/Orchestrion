function GetFFXIVInstallPath() {
    $fixedDrives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object { $_.Name }
    foreach ($fixedDrive in $fixedDrives) {
        $installPath = Join-Path $fixedDrive 'Program Files (x86)/SquareEnix/FINAL FANTASY XIV - A Realm Reborn'
        if (Test-Path $installPath -PathType Container) {
            return $installPath
        }
    }
    throw 'FFXIV のインストール先が見つかりません'
}


function GetRandomFilePathWithExtension([string]$extension) {
    do {
        $tempFilePath = Join-Path -Path $env:TEMP -ChildPath "$([System.Guid]::NewGuid().Guid).$($extension)"
    }
    while (Test-Path $tempFilePath)
    return $tempFilePath
}

function RemoveSingleParentDirectory([string]$RootDirPath) {
    $parentDir = Get-ChildItem $RootDirPath
    if ($parentDir.GetType().Name -eq 'DirectoryInfo') {
        $items = Join-Path $parentDir.FullName '*'
        Move-Item $items -Destination $RootDirPath
        Remove-Item $parentDir.FullName
    }
}
function DownloadZipAndExtract([string]$Url, [string]$ExtractPath, [switch]$Force) {
    if (Test-Path $ExtractPath -PathType Container) {
        if ($Force) {
            Remove-Item $ExtractPath -Recurse
        } else {
            throw "$ExtractPath がすでに存在しています。-Force をつけて実行するか、手動で削除してから再実行してください"
        }
    }
    New-Item $ExtractPath -ItemType Directory | Out-Null
    $zipFilePath = GetRandomFilePathWithExtension('zip')
    Invoke-RestMethod -Uri $Url -OutFile $zipFilePath
    Expand-Archive -Path $zipFilePath -DestinationPath $ExtractPath
    Remove-Item $zipFilePath
    RemoveSingleParentDirectory -RootDirPath $ExtractPath
}

function InstallSaintCoinach([switch]$Force) {
    $saintCoinachPath = '.\SaintCoinach'

    $latestBody = Invoke-RestMethod https://api.github.com/repos/xivapi/SaintCoinach/releases/latest
    $downloadUrl = ($latestBody.assets | Where-Object { $_.name -eq 'SaintCoinach.Cmd.zip' }).browser_download_url

    Write-Host 'SaintCoinach の最新版を GitHub からダウンロードして展開します'
    Write-Host "URL: $downloadUrl"
    Write-Host "展開先: $saintCoinachPath"

    DownloadZipAndExtract -Url $downloadUrl -ExtractPath $saintCoinachPath -Force:$Force
}

function InstallFFMpeg([switch]$Force) {
    $ffmpegPath = '.\ffmpeg'
    $FFMPEG_INSTALL_PATH = '.\ffmpeg\bin'
    $FFPROBE_CMD = Join-Path $FFMPEG_INSTALL_PATH ffprobe.exe

    if ((Test-Path $FFPROBE_CMD) -and (-not $Force)) {
        # already installed
        return
    }
    $latestBody = Invoke-RestMethod https://api.github.com/repos/BtbN/FFmpeg-Builds/releases/latest
    $downloadUrl = ($latestBody.assets | Where-Object { $_.name -eq 'ffmpeg-master-latest-win64-gpl-shared.zip' }).browser_download_url

    Write-Host 'ffmpeg の最新版を GitHub からダウンロードして展開します'
    Write-Host "URL: $downloadUrl"
    Write-Host "展開先: $ffmpegPath"

    DownloadZipAndExtract -Url $downloadUrl -ExtractPath $ffmpegPath -Force:$Force
}
