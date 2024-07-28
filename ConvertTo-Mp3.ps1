param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$OggPath
)
begin {
    Import-Module .\modules\module.psm1 -Force
}
process {
    # edit the path
    $FFMPEG_INSTALL_PATH = '.\ffmpeg\bin'
    $FFPROBE_CMD = Join-Path $FFMPEG_INSTALL_PATH ffprobe.exe
    $FFMPEG_CMD = Join-Path $FFMPEG_INSTALL_PATH ffmpeg.exe

    InstallFFMpeg

    $filename = (Split-Path $OggPath -Leaf) -replace '.ogg', '.mp3'

    $outputDir = '.\mp3'
    if (-not (Test-Path $outputDir)) {
        New-Item $outputDir -ItemType Directory | Out-Null
    }
    $outputPath = Join-Path $outputDir $filename
    if (Test-Path $outputPath) {
        Write-Host "$outputPath already exist. Skipping process"
        return
    }

    $json = & $FFPROBE_CMD -v quiet -print_format json -show_format -show_streams $OggPath | ConvertFrom-Json
    $loopstart = $json.streams[0].tags.LoopStart
    $loopend = $json.streams[0].tags.LoopEnd
    $duration_ts = $json.streams[0].duration_ts
    $duration = $json.streams[0].duration

    $WORKFILE_MAIN = '.\main.ogg'
    $WORKFILE_REPEAT = '.\repeat.ogg'
    $WORKFILE_LAST = '.\last.ogg'
    $WORKFILE_FADE = '.\fade.ogg'
    if ($null -eq $loopend) {
        # リピートtagなし
        & $FFMPEG_CMD -v quiet -y -i $oggPath $outputPath
        $loopcount = -1
        $comment = ''
    } elseif ($duration_ts - $loopend -eq 1) {
        # もとの長さに合わせてリピート部分を最大2回まで繰り返し、7秒/10秒かけてFadeoutする
        # 共通の部品作り
        & $FFMPEG_CMD -v quiet -y -i $oggPath -c copy $WORKFILE_MAIN
        & $FFMPEG_CMD -v quiet -y -i $oggPath -ss ($loopstart / 44100) -t 10 -c copy $WORKFILE_LAST
        & $FFMPEG_CMD -v quiet -y -i $WORKFILE_LAST -af 'afade=t=out:st=0:d=7' $WORKFILE_FADE
        if ($duration -gt 240) {
            # 4分より長い場合はリピートなし
            & $FFMPEG_CMD -v quiet -y -i $WORKFILE_MAIN -i $WORKFILE_FADE -filter_complex 'concat=n=2:v=0:a=1' $outputPath
            $fadaoutstartSec = $duration_ts / 44100
            $loopcount = 0
            $comment = "つなぎ目 $([System.TimeSpan]::new(0,0,$fadaoutstartSec).ToString())"
        } elseif ($duration -gt 120) {
            # 4分以下で2分より長い場合は1回リピート
            & $FFMPEG_CMD -v quiet -y -i $oggPath -ss ($loopstart / 44100) -c copy $WORKFILE_REPEAT
            & $FFMPEG_CMD -v quiet -y -i $WORKFILE_MAIN -i $WORKFILE_REPEAT -i $WORKFILE_FADE -filter_complex 'concat=n=3:v=0:a=1' $outputPath
            $repeatstartSec = $duration_ts / 44100
            $fadaoutstartSec = ($duration_ts - $loopstart + $duration_ts) / 44100
            $loopcount = 1
            $comment = "つなぎ目 $([System.TimeSpan]::new(0,0,$repeatstartSec).ToString()), $([System.TimeSpan]::new(0,0,$fadaoutstartSec).ToString())"
        } else {
            # 2分以下の場合は2回リピート
            & $FFMPEG_CMD -v quiet -y -i $oggPath -ss ($loopstart / 44100) -c copy $WORKFILE_REPEAT
            & $FFMPEG_CMD -v quiet -y -i $WORKFILE_MAIN -i $WORKFILE_REPEAT -i $WORKFILE_REPEAT -i $WORKFILE_FADE -filter_complex 'concat=n=4:v=0:a=1' $outputPath
            $repeat1startSec = $duration_ts / 44100
            $repeat2startSec = ($duration_ts - $loopstart + $duration_ts) / 44100
            $fadaoutstartSec = ($duration_ts - $loopstart + $duration_ts - $loopstart + $duration_ts) / 44100
            $loopcount = 2
            $comment = "つなぎ目 $([System.TimeSpan]::new(0,0,$repeat1startSec).ToString()), $([System.TimeSpan]::new(0,0,$repeat2startSec).ToString()), $([System.TimeSpan]::new(0,0,$fadaoutstartSec).ToString())"
        }
    } else {
        $loopcount = -2
        $comment = '変換できませんでした'
    }

    if (Test-Path $WORKFILE_MAIN) {
        Remove-Item $WORKFILE_MAIN
    }
    if (Test-Path $WORKFILE_REPEAT) {
        Remove-Item $WORKFILE_REPEAT
    }
    if (Test-Path $WORKFILE_LAST) {
        Remove-Item $WORKFILE_LAST
    }
    if (Test-Path $WORKFILE_FADE) {
        Remove-Item $WORKFILE_FADE
    }

    [PSCustomObject]@{
        directory = $outputDir
        filename  = Split-Path $outputPath -Leaf
        loopcount = $loopcount
        comment   = $comment
    }
}

