# === FIX MEDIAS PARA NOMES ATUALIZADOS NA FATO_FINANCEIRO ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$measuresToUpdate = @(
    @{
        Name = "Receita Total"
        Old  = "SUM(fato_financeiro[venda_liquida])"
        New  = "SUM(fato_financeiro[Receita Líquida])"
    },
    @{
        Name = "Lucro Total"
        Old  = "SUM(fato_financeiro[lucro])"
        New  = "SUM(fato_financeiro[Lucro])"
    },
    @{
        Name = "Unidades Vendidas"
        Old  = "SUM(fato_financeiro[unidades_vendidas])"
        New  = "SUM(fato_financeiro[Unidades Vendidas])"
    },
    @{
        Name = "Custo Total (CPV)"
        Old  = "SUM(fato_financeiro[custo_bens_vendidos])"
        New  = "SUM(fato_financeiro[Custo (CPV)])"
    }
)

foreach ($mDef in $measuresToUpdate) {
    $m = $tbl.Measures | Where-Object { $_.Name -eq $mDef.Name }
    if ($m) {
        $m.Expression = $m.Expression.Replace($mDef.Old, $mDef.New)
        Write-Host "Atualizado Expression da medida: $($mDef.Name)" -ForegroundColor Cyan
    }
    else {
        Write-Host "Nao encontrada: $($mDef.Name)" -ForegroundColor Red
    }
}

$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
Write-Host "`nTodas as medidas ajustadas para as novas colunas referenciadas!" -ForegroundColor Green
