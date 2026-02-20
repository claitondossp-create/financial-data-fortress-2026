# Criar medidas YoY Texto para Margem Bruta e Unidades Vendidas via TOM
$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Import-Module SqlServer
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$measures = @(
    @{
        Name       = "Margem Bruta YoY Texto"
        Expression = @'
VAR _atual = [Margem Bruta %]
VAR _anterior = CALCULATE([Margem Bruta %], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _diffPP = (_atual - _anterior) * 100
VAR _seta = IF(_diffPP >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _diffFmt = FORMAT(ABS(_diffPP), "0.0") & "pp"
RETURN
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _diffFmt & " vs ano anterior")
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
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs ano anterior")
'@
    }
)

foreach ($def in $measures) {
    $ex = $tbl.Measures | Where-Object { $_.Name -eq $def.Name }
    if ($ex) {
        Write-Host "$($def.Name) ja existe - atualizando..." -ForegroundColor Yellow
        $ex.Expression = $def.Expression
    }
    else {
        $m = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $m.Name = $def.Name
        $m.Expression = $def.Expression
        $m.DisplayFolder = "1. KPIs Estrategicos"
        $tbl.Measures.Add($m)
        Write-Host "$($def.Name) criada!" -ForegroundColor Green
    }
}

$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
Write-Host "`nConcluido!" -ForegroundColor Green
