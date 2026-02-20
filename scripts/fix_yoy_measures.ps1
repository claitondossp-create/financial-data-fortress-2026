# === CORRIGIR MEDIDAS YoY: tratar ausencia de dados + fix encoding ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

# Usar DATEADD (funciona sem date table marcada) + texto sem acentos (evita encoding)
$measures = @(
    @{
        Name       = "Receita YoY %"
        Expression = @'
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
RETURN
    DIVIDE(_atual - _anterior, _anterior, BLANK())
'@
    },
    @{
        Name       = "Receita YoY Texto"
        Expression = @'
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
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
VAR _atual = [Lucro Total]
VAR _anterior = CALCULATE([Lucro Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
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
VAR _atual = [Margem Bruta %]
VAR _anterior = CALCULATE([Margem Bruta %], DATEADD(dim_tempo[data_completa], -1, YEAR))
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
VAR _atual = [Unidades Vendidas]
VAR _anterior = CALCULATE([Unidades Vendidas], DATEADD(dim_tempo[data_completa], -1, YEAR))
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
$srv.Disconnect()
Write-Host "`nMedidas corrigidas! Agora usam DATEADD + texto sem acentos + 'N/A (sem LY)' quando nao ha dados." -ForegroundColor Green
