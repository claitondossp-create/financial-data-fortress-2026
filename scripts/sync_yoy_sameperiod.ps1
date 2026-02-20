# === SINCRONIZAR MEDIDAS YoY COM SAMEPERIODLASTYEAR VIA TOM ===
# + Marcar dim_tempo como Date Table

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
if (-not $ws) { Write-Host "ERRO: Power BI Desktop nao aberto." -ForegroundColor Red; exit 1 }
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Write-Host "Porta SSAS: $port"

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$model = $srv.Databases[0].Model

# 1. Marcar dim_tempo como Date Table
$dimTempo = $model.Tables | Where-Object { $_.Name -eq "dim_tempo" }
if ($dimTempo) {
    $dataCol = $dimTempo.Columns | Where-Object { $_.Name -eq "data_completa" }
    if ($dataCol) {
        $dimTempo.DataCategory = "Time"
        Write-Host "dim_tempo marcada como Date Table (DataCategory=Time)" -ForegroundColor Green
    }
}

# 2. Atualizar medidas YoY para SAMEPERIODLASTYEAR
$tbl = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$measures = @(
    @{
        Name       = "Receita YoY %"
        Expression = @'
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE([Receita Total], SAMEPERIODLASTYEAR(dim_tempo[data_completa]))
RETURN
    DIVIDE(_atual - _anterior, _anterior, BLANK())
'@
    },
    @{
        Name       = "Receita YoY Texto"
        Expression = @'
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE([Receita Total], SAMEPERIODLASTYEAR(dim_tempo[data_completa]))
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs período anterior")
'@
    },
    @{
        Name       = "Lucro YoY Texto"
        Expression = @'
VAR _atual = [Lucro Total]
VAR _anterior = CALCULATE([Lucro Total], SAMEPERIODLASTYEAR(dim_tempo[data_completa]))
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs período anterior")
'@
    },
    @{
        Name       = "Margem Bruta YoY Texto"
        Expression = @'
VAR _atual = [Margem Bruta %]
VAR _anterior = CALCULATE([Margem Bruta %], SAMEPERIODLASTYEAR(dim_tempo[data_completa]))
VAR _diffPP = (_atual - _anterior) * 100
VAR _seta = IF(_diffPP >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _diffFmt = FORMAT(ABS(_diffPP), "0.0") & "pp"
RETURN
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _diffFmt & " vs período anterior")
'@
    },
    @{
        Name       = "Unidades Vendidas YoY Texto"
        Expression = @'
VAR _atual = [Unidades Vendidas]
VAR _anterior = CALCULATE([Unidades Vendidas], SAMEPERIODLASTYEAR(dim_tempo[data_completa]))
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs período anterior")
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

# 3. Salvar
$model.SaveChanges()
Write-Host "`nTodas as medidas atualizadas com SAMEPERIODLASTYEAR!" -ForegroundColor Green
Write-Host "dim_tempo marcada como Date Table!" -ForegroundColor Green

$srv.Disconnect()
Write-Host "Concluido!" -ForegroundColor Green
