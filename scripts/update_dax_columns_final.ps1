# === FIX ULTIMAS MEDIDAS ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

foreach ($m in $tbl.Measures) {
    $updated = $false
    
    # regex com replace seguro: substitui caso encontre
    if ($m.Expression -match "\[lucro\]") {
        $m.Expression = $m.Expression -replace "\[lucro\]", "[Lucro]"
        $updated = $true
    }
    if ($m.Expression -match "\[unidades_vendidas\]") {
        $m.Expression = $m.Expression -replace "\[unidades_vendidas\]", "[Unidades Vendidas]"
        $updated = $true
    }
    if ($m.Expression -match "\[venda_liquida\]") {
        $m.Expression = $m.Expression -replace "\[venda_liquida\]", "[Receita Líquida]"
        $updated = $true
    }
    if ($m.Expression -match "\[custo_bens_vendidos\]") {
        $m.Expression = $m.Expression -replace "\[custo_bens_vendidos\]", "[Custo (CPV)]"
        $updated = $true
    }
    if ($m.Expression -match "\[pais\]") {
        $m.Expression = $m.Expression -replace "\[pais\]", "[País]"
        $updated = $true
    }
    if ($m.Expression -match "\[segmento_nome\]") {
        $m.Expression = $m.Expression -replace "\[segmento_nome\]", "[Segmento]"
        $updated = $true
    }

    if ($updated) {
        Write-Host "Medida corrigida: $($m.Name)" -ForegroundColor Cyan
    }
}

$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
Write-Host "Todas as dependencias quebradas do DAX foram corrigidas." -ForegroundColor Green
