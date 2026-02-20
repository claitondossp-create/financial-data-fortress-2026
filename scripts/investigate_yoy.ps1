$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

$connStr = "Provider=MSOLAP;Data Source=localhost:$port;Initial Catalog=;"
$query = @"
EVALUATE
SUMMARIZECOLUMNS(
    dim_tempo[Ano],
    dim_tempo[Mes_Nome_Abrev],
    dim_tempo[Mes],
    "Receita Total", [Receita Total],
    "Lucro Total", [Lucro Total]
)
ORDER BY
    dim_tempo[Ano],
    dim_tempo[Mes]
"@

try {
    # Load required ADO.NET assembly for ADOMD
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.AdomdClient") | Out-Null
    
    $conn = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection($connStr)
    $conn.Open()
    
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $query
    
    $da = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $da.Fill($dt) | Out-Null
    
    $dt | Format-Table -AutoSize
    
    $conn.Close()
}
catch {
    Write-Error "Failed to execute DAX query: $_"
}
