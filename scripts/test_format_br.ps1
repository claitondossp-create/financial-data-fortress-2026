$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$((Get-Module SqlServer).ModuleBase)\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables["Medidas Insights"]

# Formatando apenas 1 medida para testar a regionalização Pt-BR (que usa duplo ponto .. para escalar milhoes e virgula para decimal)
$m = $tbl.Measures["Receita Total"]
# 1. Aplicando pontos duplos e virgula (BR)
$m.FormatString = '"R$ "#.##0,0.. "Mi";-"R$ "#.##0,0.. "Mi"'
$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
Write-Host "FormatString padrao brasileiro testado em Receita Total."
