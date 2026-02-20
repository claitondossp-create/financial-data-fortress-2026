# === FASE 2: DAX DEFENSIVO E FORMATACAO DINAMICA ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

Write-Host "Iniciando injecao de DAX Defensivo e Formatacao Dinamica..." -ForegroundColor Cyan

# 1. Aplicando FormatStringExpression Dinâmica em Medidas Monetárias (Milhares e Milhões)
$dynamicFormatDAX = @'
VAR _Valor = ABS(SELECTEDMEASURE())
RETURN 
SWITCH(
    TRUE(),
    _Valor >= 1000000000, """R$"" #,0.00,,,"" Bi""",
    _Valor >= 1000000,    """R$"" #,0.00,,"" Mi""",
    _Valor >= 1000,       """R$"" #,0.00,"" K""",
    """R$"" #,0.00"
)
'@

$monetaryMeasures = @(
    "Receita Total",
    "Lucro Total",
    "Custo Total (CPV)",
    "Receita Acumulada Ano",
    "Media Movel 3 Meses",
    "Lucro Acumulado Ano"
)

foreach ($mName in $monetaryMeasures) {
    $m = $tbl.Measures | Where-Object { $_.Name -eq $mName }
    if ($m) {
        # Para que o FormatStringExpression funcione nas versões recentes do Power BI, 
        # a propriedade FormatString estática geralmente não deve conflitar
        $m.FormatStringExpression = $dynamicFormatDAX
        Write-Host "Formatacao Dinamica (K/Mi/Bi) aplicada a: $($m.Name)" -ForegroundColor Green
    }
}

# 2. Refinando DAX da Margem Bruta
$mGrossMargin = $tbl.Measures | Where-Object { $_.Name -eq "Margem Bruta %" }
if ($mGrossMargin) {
    # Usando DIVIDE nativo à prova de DivZero e BLANKs
    $mGrossMargin.Expression = "DIVIDE([Lucro Total], [Receita Total], BLANK())"
    Write-Host "DAX [Margem Bruta %] reescrita de forma Defensiva!" -ForegroundColor Green
}

# 3. Refinando Crescimento MoM %
$mMoM = $tbl.Measures | Where-Object { $_.Name -eq "Crescimento MoM %" }
if ($mMoM) {
    $mMoM.Expression = @'
VAR _Atual = [Receita Total]
VAR _Anterior = CALCULATE([Receita Total], PREVIOUSMONTH(dim_tempo[data_completa]))
RETURN
    IF(
        ISBLANK(_Anterior) || _Anterior = 0,
        BLANK(),
        DIVIDE(_Atual - _Anterior, _Anterior)
    )
'@
    Write-Host "DAX [Crescimento MoM %] reescrita de forma Defensiva!" -ForegroundColor Green
}

$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
Write-Host "Fase 2 implementada localmente no Power BI Desktop com sucesso!" -ForegroundColor Cyan
