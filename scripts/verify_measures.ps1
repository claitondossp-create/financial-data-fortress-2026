# === ATUALIZAR FORMAT STRING DA MEDIDA RECEITA TOTAL ===

# 1. Porta
$workspacesPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$workspace = Get-ChildItem -Path $workspacesPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $workspace) {
    Write-Host "ERRO: Power BI Desktop nao esta aberto." -ForegroundColor Red
    exit 1
}
$portFile = Join-Path $workspace.FullName "Data\msmdsrv.port.txt"
$port = [System.IO.File]::ReadAllText($portFile, [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Write-Host "Porta SSAS: $port"

# 2. DLLs
Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

# 3. Conectar
$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$model = $srv.Databases[0].Model
$targetTable = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

# 4. Verificar medida Receita YoY % existe e esta correta
$yoyMeasure = $targetTable.Measures | Where-Object { $_.Name -eq "Receita YoY %" }
if ($yoyMeasure) {
    Write-Host "Medida 'Receita YoY %' OK: $($yoyMeasure.Expression.Substring(0, [Math]::Min(50, $yoyMeasure.Expression.Length)))..."
}
else {
    Write-Host "Medida 'Receita YoY %' NAO existe. Criando..."
    $m = New-Object Microsoft.AnalysisServices.Tabular.Measure
    $m.Name = "Receita YoY %"
    $m.Expression = "VAR _atual = [Receita Total] VAR _anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR)) RETURN DIVIDE(_atual - _anterior, _anterior, BLANK())"
    $m.FormatString = "0.0%;-0.0%;0.0%"
    $m.DisplayFolder = "1. KPIs Estrategicos"
    $m.Description = "Variacao percentual da receita total YoY"
    $targetTable.Measures.Add($m)
    Write-Host "Medida criada."
}

# 5. Salvar
$model.SaveChanges()
Write-Host "`nModelo salvo!" -ForegroundColor Green

# 6. Listar medidas relevantes
Write-Host "`nMedidas KPI:"
$targetTable.Measures | Where-Object { $_.DisplayFolder -eq "1. KPIs Estrategicos" } | ForEach-Object {
    Write-Host "  - $($_.Name) [Format: $($_.FormatString)]"
}

$srv.Disconnect()
Write-Host "Concluido." -ForegroundColor Green
