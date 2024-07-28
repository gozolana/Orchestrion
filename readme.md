# Orchestrion

FFXIV のインゲームデータの BGM を抽出します。

デフォルトで出力された ogg ファイルのループ情報を使って、適度な長さの MP3 ファイルに変換します。
また、オーケストリオンのリストとして管理されている曲は、メタ情報付きの MP3 に変換できます。

次の 3rd Party ソフトウェアを使用し、必要であれば自動でダウンロードします。

SaintCoinach: FFXIV インゲームデータの抽出
ffmpeg: 音声ファイルの変換

## Extract-SaintCoinach.ps1

FFXIV のインゲームデータを抽出する SaintCoinach をダウンロードしてインストール後、BGM の抽出を行う。データは以下のパスに展開される。

```path
.\SaintCoinach\<パッチの日付>\music
```

## Get-Orchestrion.ps1

Extract-SaintCoinach.ps1 で抽出されたオーケストリオンの曲データを取得する。
パッチ 7.0 時点で約 620 曲の情報が取得できる。

```PowerShell
 .\Get-Orchestrion.ps1 | Select-Object -First 3 | Format-Table

Id Title        Disc Category       Track FileName                        Search
-- -----        ---- --------       ----- --------                        ------
2  水車の調べ      1 01 フィールド1     1 001 Wailers and Waterwheels.mp3 music/ffxiv/Orchestrion/BGM_ORCH_002*.ogg
3  偉大なる母港    1 01 フィールド1     2 002 I Am the Sea.mp3            music/ffxiv/Orchestrion/BGM_ORCH_003*.ogg
4  希望の都        1 01 フィールド1     3 003 A New Hope.mp3              music/ffxiv/Orchestrion/BGM_ORCH_004*.ogg
```

## ConvertTo-OrchestrionMp3.ps1

Get-Orchestrion.ps1 で取得したオーケストリン情報を引数に渡して mp3 ファイルを得る。
mp3 ファイルは 11 種類にカテゴライズされたフォルダのいずれかに出力される。

```PowerShell
$list = .\Get-Orchestrion.ps1
.\ConvertTo-OrchestrionMp3.ps1 $list[250]

directory      filename                 loopcount comment
---------      --------                 --------- -------
04 ダンジョン2 037 Lost in the Deep.mp3         1 つなぎ目 00:02:12, 00:04:11
```

全曲出力する場合は次のように実行する。ただし、時間はそれなりに掛かる

```PowerShell
.\Get-Orchestrion.ps1 | .\ConvertTo-OrchestrionMp3.ps1
```

## ConvertTo-Mp3.ps1

ogg ファイルを mp3 ファイルの変換する。出力先は、mp3 フォルダ固定。
オーケストリオンに登録されていない最新パッチの曲やレア曲を変換する場合に利用する。
オーケストリオンに登録されている曲は、メタデータを付加できる ConvertTo-OrchestrionMp3.ps1 で変換することを推奨。

ラスボス曲を変換する

```PowerShell
.\ConvertTo-Mp3.ps1 .\SaintCoinach\2024.07.10.0001.0000\music\ex5\BGM_EX5_Ban_03.ogg

directory filename           loopcount comment
--------- --------           --------- -------
.\mp3     BGM_EX5_Ban_03.mp3         1 つなぎ目 00:03:42, 00:07:12
```

パッチ 7.0 の曲を全て変換する

```PowerShell
Get-ChildItem .\SaintCoinach\2024.07.10.0001.0000\music\ex5\*.ogg | .\ConvertTo-Mp3.ps1
```
