# === APLICANDO REGRAS DE NOMENCLATURA (PATCH DA FASE 1 DE GOVERNANCA) ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$db = $srv.Databases[0]

Write-Host "Iniciando Patch de Governanca de Nomes na dim_produto..." -ForegroundColor Cyan

$tbl = $db.Model.Tables | Where-Object { $_.Name -eq "dim_produto" }
if ($tbl) {
    # Renomeando produto_sk
    $colSk = $tbl.Columns | Where-Object { $_.Name -eq "produto_sk" }
    if ($colSk) {
        # Alterar a propriedade Name faz com que a interface (Caption) mude
        # sem quebrar a referencia do SourceColumn (fisico no M)
        $colSk.Name = "Código do Produto"
        Write-Host "✅ Coluna [produto_sk] renomeada para [Código do Produto]." -ForegroundColor Green
    }

    # Renomeando produto_nome
    $colNome = $tbl.Columns | Where-Object { $_.Name -eq "produto_nome" }
    if ($colNome) {
        $colNome.Name = "Produto"
        Write-Host "✅ Coluna [produto_nome] renomeada para [Produto]." -ForegroundColor Green
    }
}

$db.Model.SaveChanges()
$srv.Disconnect()
Write-Host "Patch Ouro aplicado com sucesso para a UI de Produtos." -ForegroundColor Green
