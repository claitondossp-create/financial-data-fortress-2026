# ============================================================================
# update_measures_ptbr.ps1
# Remove medidas em inglês e recria todas em PT-BR com novos nomes de colunas.
# Requisito: Power BI Desktop aberto. Workflow: /connect-powerbi
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " ATUALIZANDO MEDIDAS DAX PARA PT-BR" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# --- 1. Conectar ---
Write-Host "`n[1/4] Conectando ao Power BI Desktop..." -ForegroundColor Yellow

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
if (-not $ws) { Write-Host "ERRO: Power BI Desktop nao esta aberto." -ForegroundColor Red; exit 1 }

$port = [System.IO.File]::ReadAllText("$($ws.FullName)\Data\msmdsrv.port.txt", [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Write-Host "  Porta: $port" -ForegroundColor Green

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$model = $srv.Databases[0].Model
Write-Host "  Conectado ao modelo: $($srv.Databases[0].Name)" -ForegroundColor Green

# --- 2. Remover medidas antigas da tabela "Medidas Insights" ---
Write-Host "`n[2/4] Removendo medidas em ingles..." -ForegroundColor Yellow

$tbl = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }
if ($tbl) {
    $names = @($tbl.Measures | ForEach-Object { $_.Name })
    foreach ($n in $names) {
        $m = $tbl.Measures[$n]
        if ($m) { $tbl.Measures.Remove($m) }
    }
    Write-Host "  $($names.Count) medidas removidas." -ForegroundColor Green
}
else {
    # Criar tabela
    $tbl = New-Object Microsoft.AnalysisServices.Tabular.Table
    $tbl.Name = "Medidas Insights"
    $part = New-Object Microsoft.AnalysisServices.Tabular.Partition
    $part.Name = "Medidas Insights_part"
    $src = New-Object Microsoft.AnalysisServices.Tabular.CalculatedPartitionSource
    $src.Expression = 'ROW("Placeholder", 1)'
    $part.Source = $src
    $tbl.Partitions.Add($part)
    $col = New-Object Microsoft.AnalysisServices.Tabular.CalculatedTableColumn
    $col.Name = "Placeholder"; $col.DataType = [Microsoft.AnalysisServices.Tabular.DataType]::Int64
    $col.IsHidden = $true; $col.SourceColumn = "Placeholder"
    $tbl.Columns.Add($col)
    $model.Tables.Add($tbl)
    Write-Host "  Tabela 'Medidas Insights' criada." -ForegroundColor Green
}

# --- 3. Criar medidas em PT-BR ---
Write-Host "`n[3/4] Criando medidas em PT-BR..." -ForegroundColor Yellow

# NOTA: As colunas foram renomeadas:
#   venda_liquida         → receita_liquida
#   custo_bens_vendidos   → custo_produtos_vendidos
#   produto_nome          → nome_produto
#   segmento_nome         → nome_segmento

$medidas = @(
    # ===== 1. KPIs ESTRATÉGICOS =====
    @{ N = "Receita Total"; D = "SUM(fato_financeiro[receita_liquida])"; P = "1. KPIs Estrategicos"; F = '$#,##0.00'; Desc = "Soma da receita liquida total" },
    @{ N = "Lucro Total"; D = "SUM(fato_financeiro[lucro])"; P = "1. KPIs Estrategicos"; F = '$#,##0.00'; Desc = "Soma do lucro total" },
    @{ N = "Margem Bruta %"; D = "DIVIDE([Lucro Total], [Receita Total], 0)"; P = "1. KPIs Estrategicos"; F = "0.0%"; Desc = "Margem bruta percentual (Lucro / Receita)" },
    @{ N = "Unidades Vendidas"; D = "SUM(fato_financeiro[unidades_vendidas])"; P = "1. KPIs Estrategicos"; F = "#,##0"; Desc = "Total de unidades vendidas" },
    @{ N = "Custo Total (CPV)"; D = "SUM(fato_financeiro[custo_produtos_vendidos])"; P = "1. KPIs Estrategicos"; F = '$#,##0.00'; Desc = "Custo total dos produtos vendidos" },
    @{ N = "Ticket Medio"; D = "DIVIDE([Receita Total], [Unidades Vendidas], 0)"; P = "1. KPIs Estrategicos"; F = '$#,##0.00'; Desc = "Valor medio por unidade vendida" },

    # ===== 2. INTELIGÊNCIA TEMPORAL =====
    @{ N = "Crescimento MoM %"; D = "VAR Atual = [Receita Total] VAR Anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, MONTH)) RETURN DIVIDE(Atual - Anterior, Anterior, BLANK())"; P = "2. Inteligencia Temporal"; F = "0.0%"; Desc = "Crescimento de receita mes a mes" },
    @{ N = "Receita Acumulada Ano"; D = "TOTALYTD([Receita Total], dim_tempo[data_completa])"; P = "2. Inteligencia Temporal"; F = '$#,##0.00'; Desc = "Receita acumulada no ano (YTD)" },
    @{ N = "Media Movel 3 Meses"; D = "AVERAGEX(DATESINPERIOD(dim_tempo[data_completa], MAX(dim_tempo[data_completa]), -3, MONTH), [Receita Total])"; P = "2. Inteligencia Temporal"; F = '$#,##0.00'; Desc = "Media movel de receita (3 meses)" },
    @{ N = "Lucro Acumulado Ano"; D = "TOTALYTD([Lucro Total], dim_tempo[data_completa])"; P = "2. Inteligencia Temporal"; F = '$#,##0.00'; Desc = "Lucro acumulado no ano (YTD)" },

    # ===== 3. PERFORMANCE GEOGRÁFICA =====
    @{ N = "Ranking Receita por Pais"; D = "RANKX(ALL(dim_geografia[pais]), [Receita Total], , DESC, DENSE)"; P = "3. Performance Geografica"; F = "0"; Desc = "Ranking de receita por pais" },
    @{ N = "Ranking Lucro por Pais"; D = "RANKX(ALL(dim_geografia[pais]), [Lucro Total], , DESC, DENSE)"; P = "3. Performance Geografica"; F = "0"; Desc = "Ranking de lucro por pais" },
    @{ N = "Contribuicao do Pais %"; D = "DIVIDE([Receita Total], CALCULATE([Receita Total], ALL(dim_geografia)), 0)"; P = "3. Performance Geografica"; F = "0.0%"; Desc = "Participacao percentual do pais na receita" },

    # ===== 4. ANÁLISE POR SEGMENTO =====
    @{ N = "Participacao Segmento %"; D = "DIVIDE([Receita Total], CALCULATE([Receita Total], ALL(dim_segmento)), 0)"; P = "4. Analise por Segmento"; F = "0.0%"; Desc = "Participacao do segmento na receita total" },
    @{ N = "Margem Lucro Segmento %"; D = "DIVIDE([Lucro Total], [Receita Total], 0)"; P = "4. Analise por Segmento"; F = "0.0%"; Desc = "Margem de lucro por segmento" },

    # ===== 5. DIAGNÓSTICO DE DESCONTOS =====
    @{ N = "Total Transacoes"; D = "COUNTROWS(fato_financeiro)"; P = "5. Diagnostico de Descontos"; F = "#,##0"; Desc = "Numero total de transacoes" },
    @{ N = "Margem por Faixa Desconto"; D = "DIVIDE([Lucro Total], [Receita Total], 0)"; P = "5. Diagnostico de Descontos"; F = "0.0%"; Desc = "Margem de lucro segmentada por faixa de desconto" },
    @{ N = "Alerta Desconto Alto"; D = "VAR M = CALCULATE([Margem Bruta %], dim_desconto[faixa_desconto] = ""High"") RETURN IF(M < 0.10, ""ALERTA: Margem critica"", ""OK"")"; P = "5. Diagnostico de Descontos"; F = ""; Desc = "Alerta quando margem com desconto alto cai abaixo de 10%" },

    # ===== 6. ANÁLISE DE PRODUTO =====
    @{ N = "Ranking Lucro Produto"; D = "RANKX(ALL(dim_produto[nome_produto]), [Lucro Total], , DESC, DENSE)"; P = "6. Analise de Produto"; F = "0"; Desc = "Ranking de produtos por lucro" },
    @{ N = "Participacao Produto %"; D = "DIVIDE([Receita Total], CALCULATE([Receita Total], ALL(dim_produto)), 0)"; P = "6. Analise de Produto"; F = "0.0%"; Desc = "Participacao do produto na receita total" },
    @{ N = "Margem vs Media"; D = "VAR Atual = [Margem Bruta %] VAR Media = CALCULATE([Margem Bruta %], ALL(dim_produto)) RETURN Atual - Media"; P = "6. Analise de Produto"; F = "+0.0%;-0.0%"; Desc = "Diferenca da margem do produto vs media geral" },
    @{ N = "Categoria BCG"; D = "VAR CM = [Margem Bruta %] VAR CV = [Unidades Vendidas] VAR AM = CALCULATE([Margem Bruta %], ALL(dim_produto)) VAR AV = CALCULATE([Unidades Vendidas], ALL(dim_produto)) RETURN SWITCH(TRUE(), CM > AM && CV > AV, ""Estrela"", CM > AM && CV <= AV, ""Vaca Leiteira"", CM <= AM && CV > AV, ""Interrogacao"", ""Abacaxi"")"; P = "6. Analise de Produto"; F = ""; Desc = "Classificacao BCG do produto" },

    # ===== 7. SAZONALIDADE =====
    @{ N = "Indice Sazonalidade"; D = "VAR MS = [Receita Total] VAR MED = DIVIDE(CALCULATE([Receita Total], ALL(dim_tempo[mes])), DISTINCTCOUNT(dim_tempo[mes]), 0) RETURN DIVIDE(MS, MED, 0)"; P = "7. Sazonalidade"; F = "0.00"; Desc = "Indice de sazonalidade (1.0=media, >1=acima, <1=abaixo)" },
    @{ N = "Melhor Trimestre"; D = "VAR Q1 = CALCULATE([Receita Total], dim_tempo[trimestre] = 1) VAR Q2 = CALCULATE([Receita Total], dim_tempo[trimestre] = 2) VAR Q3 = CALCULATE([Receita Total], dim_tempo[trimestre] = 3) VAR Q4 = CALCULATE([Receita Total], dim_tempo[trimestre] = 4) VAR MX = MAX(MAX(Q1, Q2), MAX(Q3, Q4)) RETURN SWITCH(MX, Q1, ""T1"", Q2, ""T2"", Q3, ""T3"", Q4, ""T4"")"; P = "7. Sazonalidade"; F = ""; Desc = "Trimestre com melhor receita" }
)

$created = 0
foreach ($m in $medidas) {
    try {
        $measure = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $measure.Name = $m.N
        $measure.Expression = $m.D.Trim()
        $measure.Description = $m.Desc
        $measure.DisplayFolder = $m.P
        if ($m.F) { $measure.FormatString = $m.F }
        $tbl.Measures.Add($measure)
        Write-Host "  [OK] $($m.N)" -ForegroundColor Green
        $created++
    }
    catch {
        Write-Host "  [ERRO] $($m.N): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- 4. Salvar ---
Write-Host "`n[4/4] Salvando modelo..." -ForegroundColor Yellow
$model.SaveChanges()
Write-Host "  Modelo salvo!" -ForegroundColor Green

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  $created medidas criadas em PT-BR" -ForegroundColor Green
Write-Host "  Pressione F5 no Power BI Desktop." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$srv.Disconnect()
