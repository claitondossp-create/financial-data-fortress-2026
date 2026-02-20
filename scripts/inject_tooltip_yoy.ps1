# === INJETANDO MEDIDA TOOLTIP_EXPLICACAO_YOY ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$daxExpression = @"
VAR _ReceitaAtual = [Receita Total]
VAR _ReceitaAnoAnterior = CALCULATE([Receita Total], SAMEPERIODLASTYEAR(dim_tempo[data_completa]))
VAR _YoYPercent = [Receita YoY %]

VAR _MesesComVendaAtual = 
    CALCULATE(
        DISTINCTCOUNT(dim_tempo[mes]), 
        fato_financeiro
    )

VAR _MesesComVendaAnterior = 
    CALCULATE(
        DISTINCTCOUNT(dim_tempo[mes]), 
        CALCULATETABLE(fato_financeiro, SAMEPERIODLASTYEAR(dim_tempo[data_completa]))
    )

RETURN
IF(
    _YoYPercent > 1 && NOT ISBLANK(_ReceitaAnoAnterior) && _MesesComVendaAtual > _MesesComVendaAnterior,
    "💡 Anomalia YoY Diagnosticada (" & FORMAT(_YoYPercent, "0.0%") & " de salto): O cálculo está sendo distorcido estatisticamente, pois o ano base (Anterior) registrou faturamento completo em apenas " & FORMAT(_MesesComVendaAnterior, "0") & " meses, frente a " & FORMAT(_MesesComVendaAtual, "0") & " meses operacionais do ano atual selecionado.",
    BLANK()
)
"@

$measureName = "Tooltip_Explicacao_YoY"
$existingMeasure = $tbl.Measures | Where-Object { $_.Name -eq $measureName }

if ($existingMeasure) {
    $existingMeasure.Expression = $daxExpression
    Write-Host "Medida existente [$measureName] atualizada com logica defensiva." -ForegroundColor Yellow
}
else {
    $newMeasure = New-Object Microsoft.AnalysisServices.Tabular.Measure
    $newMeasure.Name = $measureName
    $newMeasure.Expression = $daxExpression
    $newMeasure.DisplayFolder = "7. Storytelling (Textos)"
    $tbl.Measures.Add($newMeasure)
    Write-Host "Medida nova [$measureName] injetada com sucesso no TOM." -ForegroundColor Green
}

$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
