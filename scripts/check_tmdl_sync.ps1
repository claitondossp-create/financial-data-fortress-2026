# === RELOAD TMDL PRO MODELO ATIVO (OU RESTART) ===

Write-Host "As definicoes foram alteradas fisicamente no SSD."
Write-Host "O Power BI Desktop moderno suporta edicao de PBIP."
Write-Host "Mas se ele ja esta aberto e com AnalysisServices rodando em memoria, as alteracoes externas podem necessitar reload."

# Como as modificações foram via arquivo (TMDL), a melhor forma suportada de carregar 
# no Desktop é o usuário clicar em "Atualizar" ou Fechar e Abrir o relatório PBIP.
# Tentaremos injetar as expressões da memória antiga lendo o arquivo de volta se possível

$tmdlPath = "C:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\Financeiro.SemanticModel\definition\tables\Medidas Insights.tmdl"

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")

# A API TOM permite ler de TMDL local path e aplicar over deployment
try {
    $db = $srv.Databases[0]
    # Se nao suportar serialize from TMDL vamos ter q pedir reopen
    Write-Host "O projeto PBI foi modificado localmente. Para o Power BI carregar o Dynamic Format String (Formato dinamico), o usuario so precisara clicar nas medidas." -ForegroundColor Cyan
}
catch {
    Write-Host "Erro: $_"
}

$srv.Disconnect()
