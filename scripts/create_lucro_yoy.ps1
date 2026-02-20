# Criar medida Lucro YoY Texto via TOM
$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Import-Module SqlServer
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$ex = $tbl.Measures | Where-Object { $_.Name -eq "Lucro YoY Texto" }
if ($ex) {
    Write-Host "Lucro YoY Texto ja existe!" -ForegroundColor Yellow
}
else {
    $m = New-Object Microsoft.AnalysisServices.Tabular.Measure
    $m.Name = "Lucro YoY Texto"
    $m.Expression = @'
VAR _atual = [Lucro Total]
VAR _anterior = CALCULATE([Lucro Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs ano anterior")
'@
    $m.DisplayFolder = "1. KPIs Estrategicos"
    $tbl.Measures.Add($m)
    $srv.Databases[0].Model.SaveChanges()
    Write-Host "Lucro YoY Texto criada com sucesso!" -ForegroundColor Green
}

$srv.Disconnect()
