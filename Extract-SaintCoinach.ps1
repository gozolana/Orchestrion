param(
    [switch]$Force
)

Import-Module .\modules\module.psm1 -Force

try {
    $ffxivInstallPath = GetFFXIVInstallPath

    InstallSaintCoinach -Force:$Force

    Write-Host '続いて BGM と オーケストリオンに関するデータを抽出します。抽出される BGM の拡張子は ogg です'

    Push-Location .\SaintCoinach
    .\SaintCoinach.Cmd.exe `
        $ffxivInstallPath `
        'bgm' `
        'allexd Orchestrion OrchestrionCategory OrchestrionPath OrchestrionUiparam'
    Pop-Location
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
}
