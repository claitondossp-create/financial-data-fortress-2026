# ============================================================================
# create_pbi_measures.ps1
# Conecta ao Power BI Desktop via TOM e cria medidas DAX automaticamente.
# Requisito: Power BI Desktop aberto com um relatório carregado.
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " CRIANDO MEDIDAS DAX NO POWER BI DESKTOP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. Encontrar a porta local do SSAS ---
Write-Host "[1/5] Localizando instancia local do Power BI Desktop..." -ForegroundColor Yellow

$workspacesPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$workspace = Get-ChildItem -Path $workspacesPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $workspace) {
    Write-Host "ERRO: Power BI Desktop nao esta aberto." -ForegroundColor Red; exit 1
}

$portFile = Join-Path $workspace.FullName "Data\msmdsrv.port.txt"
# IMPORTANTE: o arquivo de porta é UTF-16, usar ReadAllText com Unicode
$port = [System.IO.File]::ReadAllText($portFile, [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Write-Host "  Porta SSAS: $port" -ForegroundColor Green

# --- 2. Carregar DLLs TOM do modulo SqlServer ---
Write-Host "[2/5] Carregando bibliotecas TOM..." -ForegroundColor Yellow

Import-Module SqlServer -ErrorAction Stop
$modulePath = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll",
    "Microsoft.AnalysisServices.dll",
    "Microsoft.AnalysisServices.Tabular.Json.dll",
    "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object {
    [System.Reflection.Assembly]::LoadFrom("$modulePath\$_") | Out-Null
}
Write-Host "  DLLs TOM carregadas." -ForegroundColor Green

# --- 3. Conectar ---
Write-Host "[3/5] Conectando ao modelo semantico..." -ForegroundColor Yellow

$server = New-Object Microsoft.AnalysisServices.Tabular.Server
$server.Connect("Data Source=localhost:$port")

$db = $server.Databases[0]
$model = $db.Model
Write-Host "  Modelo: $($db.Name)" -ForegroundColor Green
Write-Host "  Tabelas existentes:" -ForegroundColor Gray
foreach ($t in $model.Tables) { Write-Host "    - $($t.Name) (Measures: $($t.Measures.Count))" -ForegroundColor Gray }

# --- 4. Criar tabela de medidas ---
Write-Host "[4/5] Preparando tabela de medidas..." -ForegroundColor Yellow

$measureTableName = "Medidas Insights"
$measureTable = $model.Tables | Where-Object { $_.Name -eq $measureTableName }

if (-not $measureTable) {
    $measureTable = New-Object Microsoft.AnalysisServices.Tabular.Table
    $measureTable.Name = $measureTableName

    $partition = New-Object Microsoft.AnalysisServices.Tabular.Partition
    $partition.Name = "${measureTableName}_part"
    $src = New-Object Microsoft.AnalysisServices.Tabular.CalculatedPartitionSource
    $src.Expression = 'ROW("Placeholder", 1)'
    $partition.Source = $src
    $measureTable.Partitions.Add($partition)

    $col = New-Object Microsoft.AnalysisServices.Tabular.CalculatedTableColumn
    $col.Name = "Placeholder"
    $col.DataType = [Microsoft.AnalysisServices.Tabular.DataType]::Int64
    $col.IsHidden = $true
    $col.SourceColumn = "Placeholder"
    $measureTable.Columns.Add($col)

    $model.Tables.Add($measureTable)
    Write-Host "  Tabela '$measureTableName' criada." -ForegroundColor Green
}
else {
    Write-Host "  Tabela '$measureTableName' ja existe." -ForegroundColor Green
}

# --- 5. Definir e injetar medidas ---
Write-Host "[5/5] Injetando medidas DAX..." -ForegroundColor Yellow

$measures = @(
    # === KPIs ESTRATÉGICOS ===
    @{ N = "Total Sales"; D = "SUM(fato_financeiro[venda_liquida])"; F = "1. KPIs Estrategicos"; Fmt = '$#,##0.00'; Desc = "Soma total de vendas liquidas" },
    @{ N = "Total Profit"; D = "SUM(fato_financeiro[lucro])"; F = "1. KPIs Estrategicos"; Fmt = '$#,##0.00'; Desc = "Soma total do lucro" },
    @{ N = "Gross Margin %"; D = "DIVIDE([Total Profit], [Total Sales], 0)"; F = "1. KPIs Estrategicos"; Fmt = "0.0%"; Desc = "Margem bruta percentual" },
    @{ N = "Total Units Sold"; D = "SUM(fato_financeiro[unidades_vendidas])"; F = "1. KPIs Estrategicos"; Fmt = "#,##0"; Desc = "Total de unidades vendidas" },
    @{ N = "Total COGS"; D = "SUM(fato_financeiro[custo_bens_vendidos])"; F = "1. KPIs Estrategicos"; Fmt = '$#,##0.00'; Desc = "Custo total dos bens vendidos" },
    @{ N = "Avg Ticket"; D = "DIVIDE([Total Sales], [Total Units Sold], 0)"; F = "1. KPIs Estrategicos"; Fmt = '$#,##0.00'; Desc = "Ticket medio" },

    # === TIME INTELLIGENCE ===
    @{ N = "Sales MoM Growth %"; D = "VAR Cur = [Total Sales] VAR Prev = CALCULATE([Total Sales], DATEADD(dim_tempo[data_completa], -1, MONTH)) RETURN DIVIDE(Cur - Prev, Prev, BLANK())"; F = "2. Time Intelligence"; Fmt = "0.0%"; Desc = "Crescimento de vendas mes a mes" },
    @{ N = "Sales YTD"; D = "TOTALYTD([Total Sales], dim_tempo[data_completa])"; F = "2. Time Intelligence"; Fmt = '$#,##0.00'; Desc = "Vendas acumuladas no ano" },
    @{ N = "Sales Moving Avg 3M"; D = "AVERAGEX(DATESINPERIOD(dim_tempo[data_completa], MAX(dim_tempo[data_completa]), -3, MONTH), [Total Sales])"; F = "2. Time Intelligence"; Fmt = '$#,##0.00'; Desc = "Media movel 3 meses" },
    @{ N = "Profit YTD"; D = "TOTALYTD([Total Profit], dim_tempo[data_completa])"; F = "2. Time Intelligence"; Fmt = '$#,##0.00'; Desc = "Lucro acumulado no ano" },

    # === PERFORMANCE GEOGRÁFICA ===
    @{ N = "Sales by Country Rank"; D = "RANKX(ALL(dim_geografia[pais]), [Total Sales], , DESC, DENSE)"; F = "3. Performance Geografica"; Fmt = "0"; Desc = "Ranking de vendas por pais" },
    @{ N = "Profit by Country Rank"; D = "RANKX(ALL(dim_geografia[pais]), [Total Profit], , DESC, DENSE)"; F = "3. Performance Geografica"; Fmt = "0"; Desc = "Ranking de lucro por pais" },
    @{ N = "Country Contribution %"; D = "DIVIDE([Total Sales], CALCULATE([Total Sales], ALL(dim_geografia)), 0)"; F = "3. Performance Geografica"; Fmt = "0.0%"; Desc = "Contribuicao do pais" },

    # === SEGMENTO ===
    @{ N = "Segment Share %"; D = "DIVIDE([Total Sales], CALCULATE([Total Sales], ALL(dim_segmento)), 0)"; F = "4. Analise por Segmento"; Fmt = "0.0%"; Desc = "Participacao do segmento" },
    @{ N = "Segment Profit Margin %"; D = "DIVIDE([Total Profit], [Total Sales], 0)"; F = "4. Analise por Segmento"; Fmt = "0.0%"; Desc = "Margem de lucro por segmento" },

    # === DIAGNÓSTICO DESCONTOS ===
    @{ N = "Transactions Count"; D = "COUNTROWS(fato_financeiro)"; F = "5. Diagnostico Descontos"; Fmt = "#,##0"; Desc = "Total de transacoes" },
    @{ N = "Profit Margin by Discount"; D = "DIVIDE([Total Profit], [Total Sales], 0)"; F = "5. Diagnostico Descontos"; Fmt = "0.0%"; Desc = "Margem por faixa de desconto" },
    @{ N = "High Discount Alert"; D = "VAR M = CALCULATE([Gross Margin %], dim_desconto[faixa_desconto] = ""High"") RETURN IF(M < 0.10, ""ALERTA: Margem critica"", ""OK"")"; F = "5. Diagnostico Descontos"; Fmt = ""; Desc = "Alerta de margem critica" },

    # === ANÁLISE PRODUTO ===
    @{ N = "Product Profit Rank"; D = "RANKX(ALL(dim_produto[produto_nome]), [Total Profit], , DESC, DENSE)"; F = "6. Analise Produto"; Fmt = "0"; Desc = "Ranking de produtos" },
    @{ N = "Product Revenue Share %"; D = "DIVIDE([Total Sales], CALCULATE([Total Sales], ALL(dim_produto)), 0)"; F = "6. Analise Produto"; Fmt = "0.0%"; Desc = "Participacao na receita" },
    @{ N = "Product Margin vs Avg"; D = "VAR Cur = [Gross Margin %] VAR Avg = CALCULATE([Gross Margin %], ALL(dim_produto)) RETURN Cur - Avg"; F = "6. Analise Produto"; Fmt = "+0.0%;-0.0%"; Desc = "Diferenca vs media" },
    @{ N = "BCG Category"; D = "VAR CM = [Gross Margin %] VAR CV = [Total Units Sold] VAR AM = CALCULATE([Gross Margin %], ALL(dim_produto)) VAR AV = CALCULATE([Total Units Sold], ALL(dim_produto)) RETURN SWITCH(TRUE(), CM > AM && CV > AV, ""Estrela"", CM > AM && CV <= AV, ""Vaca Leiteira"", CM <= AM && CV > AV, ""Interrogacao"", ""Abacaxi"")"; F = "6. Analise Produto"; Fmt = ""; Desc = "Classificacao BCG" },

    # === SAZONALIDADE ===
    @{ N = "Sales Seasonality Index"; D = "VAR MS = [Total Sales] VAR AVG_MS = DIVIDE(CALCULATE([Total Sales], ALL(dim_tempo[mes])), DISTINCTCOUNT(dim_tempo[mes]), 0) RETURN DIVIDE(MS, AVG_MS, 0)"; F = "7. Sazonalidade"; Fmt = "0.00"; Desc = "Indice de sazonalidade" },
    @{ N = "Best Quarter"; D = "VAR Q1 = CALCULATE([Total Sales], dim_tempo[trimestre] = 1) VAR Q2 = CALCULATE([Total Sales], dim_tempo[trimestre] = 2) VAR Q3 = CALCULATE([Total Sales], dim_tempo[trimestre] = 3) VAR Q4 = CALCULATE([Total Sales], dim_tempo[trimestre] = 4) VAR MX = MAX(MAX(Q1, Q2), MAX(Q3, Q4)) RETURN SWITCH(MX, Q1, ""Q1"", Q2, ""Q2"", Q3, ""Q3"", Q4, ""Q4"")"; F = "7. Sazonalidade"; Fmt = ""; Desc = "Melhor trimestre" }
)

$created = 0; $skipped = 0

foreach ($m in $measures) {
    $existing = $measureTable.Measures | Where-Object { $_.Name -eq $m.N }
    if ($existing) {
        Write-Host "  [SKIP] $($m.N)" -ForegroundColor DarkYellow
        $skipped++; continue
    }

    try {
        $measure = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $measure.Name = $m.N
        $measure.Expression = $m.D.Trim()
        $measure.Description = $m.Desc
        if ($m.F) { $measure.DisplayFolder = $m.F }
        if ($m.Fmt) { $measure.FormatString = $m.Fmt }
        $measureTable.Measures.Add($measure)
        Write-Host "  [OK] $($m.N)" -ForegroundColor Green
        $created++
    }
    catch {
        Write-Host "  [ERRO] $($m.N): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Salvando alteracoes..." -ForegroundColor Yellow
$model.SaveChanges()
Write-Host "  Modelo salvo com sucesso!" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " RESUMO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Medidas criadas:  $created" -ForegroundColor Green
Write-Host "  Medidas puladas:  $skipped" -ForegroundColor Yellow
Write-Host "  Tabela: $measureTableName" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pressione F5 no Power BI Desktop para atualizar." -ForegroundColor Green

$server.Disconnect()
