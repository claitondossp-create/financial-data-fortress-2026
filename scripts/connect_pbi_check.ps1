# Verificar conexao com Power BI Desktop via TOM
$workspacesPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$workspace = Get-ChildItem -Path $workspacesPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $workspace) {
    Write-Host "ERRO: Power BI Desktop nao esta aberto ou nenhum relatorio carregado."
    exit 1
}

$portFile = Join-Path $workspace.FullName "Data\msmdsrv.port.txt"
$port = [System.IO.File]::ReadAllText($portFile, [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Write-Host "Porta SSAS local: $port"

# Carregar DLLs TOM
Import-Module SqlServer -ErrorAction Stop
$modulePath = (Get-Module SqlServer).ModuleBase
$dlls = @(
    "Microsoft.AnalysisServices.Core.dll",
    "Microsoft.AnalysisServices.dll",
    "Microsoft.AnalysisServices.Tabular.Json.dll",
    "Microsoft.AnalysisServices.Tabular.dll"
)
foreach ($dll in $dlls) {
    [System.Reflection.Assembly]::LoadFrom("$modulePath\$dll") | Out-Null
}
Write-Host "DLLs TOM carregadas com sucesso."

# Conectar ao modelo
$server = New-Object Microsoft.AnalysisServices.Tabular.Server
$server.Connect("Data Source=localhost:$port")
$db = $server.Databases[0]
$model = $db.Model
Write-Host "Conectado ao modelo: $($db.Name)"
Write-Host "Tabelas: $($model.Tables.Count)"

# Listar medidas da tabela Medidas Insights
$targetTable = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }
if ($targetTable) {
    Write-Host "`nMedidas na tabela 'Medidas Insights':"
    foreach ($m in $targetTable.Measures) {
        Write-Host "  - $($m.Name) [$($m.DisplayFolder)]"
    }
}

# Verificar se existe medida de variacao YoY para Receita
$yoyMeasure = $targetTable.Measures | Where-Object { $_.Name -eq "Receita YoY %" }
if ($yoyMeasure) {
    Write-Host "`nMedida 'Receita YoY %' ja existe:"
    Write-Host "  DAX: $($yoyMeasure.Expression)"
}
else {
    Write-Host "`nMedida 'Receita YoY %' NAO existe."
}

$server.Disconnect()
Write-Host "`nDesconectado."
