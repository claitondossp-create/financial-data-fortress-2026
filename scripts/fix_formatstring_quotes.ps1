# === FIX FORMATSTRING (BARRAS E ASPAS LITERAIS) ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$targetMeasures = @("Receita Total", "Lucro Total", "Custo Total (CPV)", "Receita Acumulada Ano", "Lucro Acumulado Ano")

# Usando single quotes no Powershell para agrupar as double quotes intactas (sem escapes (\))
$correctFormat = '"R$ "#,##0.0,, "Mi";-"R$ "#,##0.0,, "Mi"'

foreach ($m in $tbl.Measures) {
    if ($targetMeasures -contains $m.Name) {
        $m.FormatString = $correctFormat
        Write-Host "Corrigido FormatString para: $($m.Name)" -ForegroundColor Green
    }
}

$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
Write-Host "FormatStrings higienizados com sucesso." -ForegroundColor Cyan
