$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

$connStr = "Provider=MSOLAP;Data Source=localhost:$port;"

$query = @"
EVALUATE
SUMMARIZECOLUMNS(
    dim_tempo[ano],
    dim_tempo[mes],
    "Receita Total", [Receita Total],
    "Lucro Total", [Lucro Total]
)
ORDER BY
    dim_tempo[ano],
    dim_tempo[mes]
"@

$conn = New-Object System.Data.OleDb.OleDbConnection($connStr)
$conn.Open()

$cmd = $conn.CreateCommand()
$cmd.CommandText = $query

$da = New-Object System.Data.OleDb.OleDbDataAdapter($cmd)
$dt = New-Object System.Data.DataTable
$da.Fill($dt) | Out-Null

$dt | Format-Table -AutoSize

$conn.Close()
