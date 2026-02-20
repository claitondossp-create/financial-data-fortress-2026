# === FIX DEFINITIVO: Medidas YoY com MIN/MAX date manual ===
# Funciona independente do tipo de slicer (LocalDateTable ou dim_tempo)

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$measures = @(
    @{
        Name       = "Receita YoY %"
        Expression = @'
VAR _minDate = MIN(dim_tempo[data_completa])
VAR _maxDate = MAX(dim_tempo[data_completa])
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE(
    [Receita Total],
    REMOVEFILTERS(dim_tempo),
    dim_tempo[data_completa] >= DATE(YEAR(_minDate) - 1, MONTH(_minDate), DAY(_minDate)) &&
    dim_tempo[data_completa] <= DATE(YEAR(_maxDate) - 1, MONTH(_maxDate), DAY(_maxDate))
)
RETURN
    DIVIDE(_atual - _anterior, _anterior, BLANK())
'@
    },
    @{
        Name       = "Receita YoY Texto"
        Expression = @'
VAR _minDate = MIN(dim_tempo[data_completa])
VAR _maxDate = MAX(dim_tempo[data_completa])
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE(
    [Receita Total],
    REMOVEFILTERS(dim_tempo),
    dim_tempo[data_completa] >= DATE(YEAR(_minDate) - 1, MONTH(_minDate), DAY(_minDate)) &&
    dim_tempo[data_completa] <= DATE(YEAR(_maxDate) - 1, MONTH(_maxDate), DAY(_maxDate))
)
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "N/A (sem LY)", _seta & " " & _pctFmt & " vs LY")
'@
    },
    @{
        Name       = "Lucro YoY Texto"
        Expression = @'
VAR _minDate = MIN(dim_tempo[data_completa])
VAR _maxDate = MAX(dim_tempo[data_completa])
VAR _atual = [Lucro Total]
VAR _anterior = CALCULATE(
    [Lucro Total],
    REMOVEFILTERS(dim_tempo),
    dim_tempo[data_completa] >= DATE(YEAR(_minDate) - 1, MONTH(_minDate), DAY(_minDate)) &&
    dim_tempo[data_completa] <= DATE(YEAR(_maxDate) - 1, MONTH(_maxDate), DAY(_maxDate))
)
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "N/A (sem LY)", _seta & " " & _pctFmt & " vs LY")
'@
    },
    @{
        Name       = "Margem Bruta YoY Texto"
        Expression = @'
VAR _minDate = MIN(dim_tempo[data_completa])
VAR _maxDate = MAX(dim_tempo[data_completa])
VAR _atual = [Margem Bruta %]
VAR _anterior = CALCULATE(
    [Margem Bruta %],
    REMOVEFILTERS(dim_tempo),
    dim_tempo[data_completa] >= DATE(YEAR(_minDate) - 1, MONTH(_minDate), DAY(_minDate)) &&
    dim_tempo[data_completa] <= DATE(YEAR(_maxDate) - 1, MONTH(_maxDate), DAY(_maxDate))
)
VAR _diffPP = (_atual - _anterior) * 100
VAR _seta = IF(_diffPP >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _diffFmt = FORMAT(ABS(_diffPP), "0.0") & "pp"
RETURN
    IF(ISBLANK(_anterior), "N/A (sem LY)", _seta & " " & _diffFmt & " vs LY")
'@
    },
    @{
        Name       = "Unidades Vendidas YoY Texto"
        Expression = @'
VAR _minDate = MIN(dim_tempo[data_completa])
VAR _maxDate = MAX(dim_tempo[data_completa])
VAR _atual = [Unidades Vendidas]
VAR _anterior = CALCULATE(
    [Unidades Vendidas],
    REMOVEFILTERS(dim_tempo),
    dim_tempo[data_completa] >= DATE(YEAR(_minDate) - 1, MONTH(_minDate), DAY(_minDate)) &&
    dim_tempo[data_completa] <= DATE(YEAR(_maxDate) - 1, MONTH(_maxDate), DAY(_maxDate))
)
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "N/A (sem LY)", _seta & " " & _pctFmt & " vs LY")
'@
    }
)

foreach ($def in $measures) {
    $m = $tbl.Measures | Where-Object { $_.Name -eq $def.Name }
    if ($m) {
        $m.Expression = $def.Expression
        Write-Host "Atualizada: $($def.Name)" -ForegroundColor Cyan
    }
    else {
        $newM = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $newM.Name = $def.Name
        $newM.Expression = $def.Expression
        $newM.DisplayFolder = "1. KPIs Estrategicos"
        $tbl.Measures.Add($newM)
        Write-Host "Criada: $($def.Name)" -ForegroundColor Green
    }
}

$srv.Databases[0].Model.SaveChanges()

# Testar Q3 2014 vs Q3 2013
Write-Host "`n=== Testando Q3 2014 vs Q3 2013 ===" -ForegroundColor Yellow
$connStr = "Provider=MSOLAP;Data Source=localhost:$port;Initial Catalog=$($srv.Databases[0].Name)"
$conn = New-Object System.Data.OleDb.OleDbConnection($connStr)
$conn.Open()

$testQ = @"
EVALUATE
CALCULATETABLE(
    ROW(
        "Q3_2014_Receita", CALCULATE([Receita Total], dim_tempo[ano] = 2014, dim_tempo[trimestre] = 3),
        "Q3_2014_YoY_Texto", CALCULATE([Receita YoY Texto], dim_tempo[ano] = 2014, dim_tempo[trimestre] = 3),
        "Q3_2013_Receita", CALCULATE([Receita Total], dim_tempo[ano] = 2013, dim_tempo[trimestre] = 3),
        "Q1_2014_YoY_Texto", CALCULATE([Receita YoY Texto], dim_tempo[ano] = 2014, dim_tempo[trimestre] = 1)
    )
)
"@

$cmd = $conn.CreateCommand()
$cmd.CommandText = $testQ
try {
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        Write-Host "Q3 2014 Receita: $($reader[0])" -ForegroundColor Green
        Write-Host "Q3 2014 YoY Texto: $($reader[1])" -ForegroundColor Green
        Write-Host "Q3 2013 Receita: $($reader[2])" -ForegroundColor Green
        Write-Host "Q1 2014 YoY Texto (sem LY): $($reader[3])" -ForegroundColor Yellow
    }
    $reader.Close()
}
catch {
    Write-Host "Erro no teste: $($_.Exception.Message)" -ForegroundColor Red
}

$conn.Close()
$srv.Disconnect()
Write-Host "`nConcluido!" -ForegroundColor Green
