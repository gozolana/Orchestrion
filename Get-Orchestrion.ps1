$exdPath = '.\SaintCoinach\*\exd-all'

function ReadOrchestrionCsv([string]$directory) {
    $path = Join-Path $directory 'Orchestrion.ja.csv'
    $rawContent = Get-Content $path -Raw
    $lines = (($rawContent -replace '[^"]\r\n', '') -split '\r\n' | Select-Object -Skip 1)
    ConvertFrom-Csv -Header 'Id', 'Title', 'Description' $lines
}

function ReadOrchestrionCsvEng([string]$directory) {
    $path = Join-Path $directory 'Orchestrion.en.csv'
    $rawContent = Get-Content $path -Raw
    $lines = (($rawContent -replace '[^"]\r\n', '') -split '\r\n' | Select-Object -Skip 1)
    ConvertFrom-Csv -Header 'Id', 'Title', 'Description' $lines
}

function ReadOrchestrionPathCsv([string]$directory) {
    $path = Join-Path $directory 'OrchestrionPath.csv'
    $lines = Get-Content $path | Select-Object -Skip 4
    ConvertFrom-Csv -Header 'Id', 'Path' $lines
}

function ReadOrchestrionUiparamCsv([string]$directory) {
    $path = Join-Path $directory 'OrchestrionUiparam.csv'
    $lines = Get-Content $path | Select-Object -Skip 4
    ConvertFrom-Csv -Header 'Id', 'Category', 'Track' $lines
}

function ReadOrchestrionCategoryCsv([string]$directory) {
    $path = Join-Path $directory 'OrchestrionCategory.ja.csv'
    $lines = Get-Content $path | Select-Object -Skip 4
    ConvertFrom-Csv -Header 'Id', 'Name', 'Flag1', 'Image', 'SortOrder', 'Flag2'  $lines
}

$titles = ReadOrchestrionCsv -directory $exdPath
$fileNames = ReadOrchestrionCsvEng -directory $exdPath
$paths = ReadOrchestrionPathCsv $exdPath
$uiParams = ReadOrchestrionUiparamCsv $exdPath

$catetoryNameHash = @{
    'Locales I'              = '01 フィールド1'
    'Locales II'             = '02 フィールド2'
    'Dungeons I'             = '03 ダンジョン1'
    'Dungeons II'            = '04 ダンジョン2'
    'Trials'                 = '05 討滅戦'
    'Raids I'                = '06 レイド1'
    'Raids II'               = '07 レイド2'
    'Ambient'                = '08 環境音'
    'Quests'                 = '09 クエスト関連'
    'Others'                 = '10 その他'
    'Seasonal'               = '11 シーズナル'
    'Online Store & Bonuses' = '12 購入・特典'
}

$catetoryDiscHash = @{
    'Locales I'              = 1
    'Locales II'             = 2
    'Dungeons I'             = 3
    'Dungeons II'            = 4
    'Trials'                 = 5
    'Raids I'                = 6
    'Raids II'               = 7
    'Ambient'                = 8
    'Quests'                 = 9
    'Others'                 = 10
    'Seasonal'               = 11
    'Online Store & Bonuses' = 12
}

if ($titles.Length -ne $paths.Length) {
    throw "Mismatch of csv. Titles: $($titles.Length) vs Paths: $($paths.Length)"
}
if ($titles.Length -ne $uiParams.Length) {
    throw "Mismatch of csv. Titles: $($titles.Length) vs Uiparams: $($uiParam.Length)"
}

$list = for ($i = 0; $i -lt $titles.Length; $i++) {
    if ($paths[$i].Path -eq '') {
        continue
    }

    if ([int]$uiParams[$i].Track -ne 65535) {
        $track = [int]$uiParams[$i].Track
    } else {
        $track = [int]($paths[$i].Path -Replace '^.+_(\d+)\.scd$', '$1')
    }

    $fileName = "$(([string]$track).PadLeft(3, '0')) $($fileNames[$i].Title.Split([IO.Path]::GetInvalidFileNameChars()) -join '').mp3"

    [PSCustomObject]@{
        Id       = $titles[$i].Id
        Title    = $titles[$i].Title
        Disc     = $catetoryDiscHash[$uiParams[$i].Category]
        Category = $catetoryNameHash[$uiParams[$i].Category]
        Track    = $track
        FileName = $fileName
        Search   = $paths[$i].Path -Replace '\.scd$', '*.ogg'
    }
}

$list | Sort-Object -Property Category, FileName
