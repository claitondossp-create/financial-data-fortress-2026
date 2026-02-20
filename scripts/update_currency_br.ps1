# === ATUALIZAR FORMATO DE MOEDA PARA R$ VIA TOM ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$measuresToUpdate = @(
    "Receita Total",
    "Lucro Total",
    "Custo Total (CPV)",
    "Ticket Medio",
    "Receita Acumulada Ano",
    "Media Movel 3 Meses",
    "Lucro Acumulado Ano"
)

# Formato brasileiro: R$ 1.000,00
$brFormat = '"R$"\ #,0.00;-"R$"\ #,0.00;"R$"\ #,0.00'

foreach ($mName in $measuresToUpdate) {
    $m = $tbl.Measures | Where-Object { $_.Name -eq $mName }
    if ($m) {
        $m.FormatString = $brFormat
        Write-Host "Atualizado: $mName -> $brFormat" -ForegroundColor Cyan
    }
    else {
        Write-Host "Nao encontrada: $mName" -ForegroundColor Red
    }
}

$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
Write-Host "`nTodas as medidas monetarias atualizadas para R$!" -ForegroundColor Green
