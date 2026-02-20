# === FIX OUTRAS MEDIDAS QUEBRADAS (RANKING) ===

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
        Name = "Ranking Lucro por Pais"
        Old  = "dim_geografia[pais]"
        New  = "dim_geografia[País]"
    },
    @{
        Name = "Ranking Receita por Pais"
        Old  = "dim_geografia[pais]"
        New  = "dim_geografia[País]"
    },
    @{
        Name = "Contribuicao do Pais %"
        Old  = "dim_geografia[pais]"
        New  = "dim_geografia[País]"
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
Write-Host "`nOutras medidas ajustadas para as novas colunas referenciadas!" -ForegroundColor Green
