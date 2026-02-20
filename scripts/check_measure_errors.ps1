# === CHECK MEDIDAS COM ERRO ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$errors = 0
foreach ($m in $tbl.Measures) {
    if ($m.Expression -match "\[lucro\]|\[unidades_vendidas\]|\[custo_bens_vendidos\]|\[venda_liquida\]|\[pais\]|\[segmento_nome\]") {
        Write-Host "ALERTA: A medida '$($m.Name)' ainda usa colunas antigas!" -ForegroundColor Yellow
        $errors++
    }
}

if ($errors -eq 0) {
    Write-Host "Nenhuma medida usando nomes antigos de coluna encontrada!" -ForegroundColor Green
}

$srv.Disconnect()
