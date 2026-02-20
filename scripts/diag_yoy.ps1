# === FIX: Marcar dim_tempo como Date Table (com coluna-chave) + Corrigir medidas ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Write-Host "Porta SSAS: $port"

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$model = $srv.Databases[0].Model

# 1. Verificar dados em dim_tempo
Write-Host "`n=== Verificando dados ===" -ForegroundColor Yellow
$result = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "dim_tempo" }
Write-Host "dim_tempo colunas: $($result.Columns.Count)"
Write-Host "dim_tempo DataCategory: $($result.DataCategory)"

# 2. Testar medida com DAX Query
Write-Host "`n=== Testando medidas com DAX ===" -ForegroundColor Yellow
try {
    $connStr = "Provider=MSOLAP;Data Source=localhost:$port;Initial Catalog=$($srv.Databases[0].Name)"
    $q1 = "EVALUATE ROW(""Total"", [Receita Total])"
    $q2 = @"
EVALUATE
SUMMARIZECOLUMNS(
    dim_tempo[ano],
    dim_tempo[trimestre],
    "Receita", [Receita Total],
    "Lucro", [Lucro Total]
)
"@
    
    $conn = New-Object System.Data.OleDb.OleDbConnection($connStr)
    $conn.Open()
    
    # Query 1: Total geral
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $q1
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        Write-Host "Receita Total (sem filtro): $($reader[0])" -ForegroundColor Cyan
    }
    $reader.Close()
    
    # Query 2: Por ano/trimestre
    $cmd2 = $conn.CreateCommand()
    $cmd2.CommandText = $q2
    $reader2 = $cmd2.ExecuteReader()
    Write-Host "`nAno | Trim | Receita | Lucro"
    Write-Host "----+------+---------+------"
    while ($reader2.Read()) {
        Write-Host "$($reader2[0]) | Q$($reader2[1])   | $($reader2[2]) | $($reader2[3])"
    }
    $reader2.Close()
    
    # Query 3: Testar SAMEPERIODLASTYEAR explicitamente
    $q3 = @"
EVALUATE
CALCULATETABLE(
    ROW(
        "Receita_2014_Q1", CALCULATE([Receita Total], dim_tempo[ano] = 2014, dim_tempo[trimestre] = 1),
        "Receita_2013_Q1", CALCULATE([Receita Total], dim_tempo[ano] = 2013, dim_tempo[trimestre] = 1),
        "SPLY_Test", CALCULATE([Receita Total], SAMEPERIODLASTYEAR(dim_tempo[data_completa]), dim_tempo[ano] = 2014, dim_tempo[trimestre] = 1)
    )
)
"@
    $cmd3 = $conn.CreateCommand()
    $cmd3.CommandText = $q3
    try {
        $reader3 = $cmd3.ExecuteReader()
        while ($reader3.Read()) {
            Write-Host "`nReceita 2014 Q1: $($reader3[0])" -ForegroundColor Green
            Write-Host "Receita 2013 Q1: $($reader3[1])" -ForegroundColor Green
            Write-Host "SAMEPERIODLASTYEAR test: $($reader3[2])" -ForegroundColor Green
        }
        $reader3.Close()
    }
    catch {
        Write-Host "Erro SAMEPERIODLASTYEAR: $($_.Exception.Message)" -ForegroundColor Red
        
        # Tentar com DATEADD
        $q4 = @"
EVALUATE
CALCULATETABLE(
    ROW(
        "Receita_2014_Q1", CALCULATE([Receita Total], dim_tempo[ano] = 2014, dim_tempo[trimestre] = 1),
        "Receita_2013_Q1", CALCULATE([Receita Total], dim_tempo[ano] = 2013, dim_tempo[trimestre] = 1),
        "DATEADD_Test", CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR), dim_tempo[ano] = 2014, dim_tempo[trimestre] = 1)
    )
)
"@
        $cmd4 = $conn.CreateCommand()
        $cmd4.CommandText = $q4
        try {
            $reader4 = $cmd4.ExecuteReader()
            while ($reader4.Read()) {
                Write-Host "`nReceita 2014 Q1: $($reader4[0])" -ForegroundColor Green
                Write-Host "Receita 2013 Q1: $($reader4[1])" -ForegroundColor Green  
                Write-Host "DATEADD test: $($reader4[2])" -ForegroundColor Green
            }
            $reader4.Close()
        }
        catch {
            Write-Host "Erro DATEADD tambem: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    $conn.Close()
}
catch {
    Write-Host "Erro ao executar DAX: $($_.Exception.Message)" -ForegroundColor Red
}

$srv.Disconnect()
Write-Host "`nDiagnostico concluido!" -ForegroundColor Green
