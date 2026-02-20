# ============================================================================
# fix_measures.ps1
# Corrige todas as medidas DAX para usar os nomes de colunas reais do modelo.
# ============================================================================
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " CORRIGINDO MEDIDAS DAX" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Import-Module SqlServer
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll",
    "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") |
ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

# Encontrar workspace ativo com medidas
$wsPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$workspaces = Get-ChildItem $wsPath -Directory

$srv = $null
$model = $null

foreach ($ws in $workspaces) {
    $pf = Join-Path $ws.FullName "Data\msmdsrv.port.txt"
    if (Test-Path $pf) {
        $port = [System.IO.File]::ReadAllText($pf, [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
        try {
            $s = New-Object Microsoft.AnalysisServices.Tabular.Server
            $s.Connect("Data Source=localhost:$port")
            $db = $s.Databases[0]
            $mt = $db.Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }
            if ($mt -and $mt.Measures.Count -gt 0) {
                $srv = $s
                $model = $db.Model
                Write-Host "  Conectado na porta $port" -ForegroundColor Green
                break
            }
            $s.Disconnect()
        }
        catch {}
    }
}

if (-not $srv) { Write-Host "ERRO: Nao encontrou modelo com medidas." -ForegroundColor Red; exit 1 }

# Verificar colunas reais
Write-Host "`nColunas reais no modelo:" -ForegroundColor Yellow
$fato = $model.Tables | Where-Object { $_.Name -eq "fato_financeiro" }
foreach ($c in $fato.Columns) {
    if ($c.Name -notlike "RowNumber*") { Write-Host "  fato: $($c.Name)" -ForegroundColor Gray }
}

# Remover medidas existentes
$tbl = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }
$names = @($tbl.Measures | ForEach-Object { $_.Name })
foreach ($n in $names) {
    $m = $tbl.Measures[$n]
    if ($m) { $tbl.Measures.Remove($m) | Out-Null }
}
Write-Host "`n$($names.Count) medidas removidas." -ForegroundColor Yellow

# === MEDIDAS CORRIGIDAS (usando nomes REAIS do modelo) ===
# Colunas reais: venda_liquida, custo_bens_vendidos, produto_nome, segmento_nome
$medidas = @(
    # 1. KPIs Estrategicos
    @{ N = "Receita Total"; D = "SUM(fato_financeiro[venda_liquida])"; P = "1. KPIs Estrategicos"; F = '$#,##0.00'; Desc = "Soma da receita liquida total" },
    @{ N = "Lucro Total"; D = "SUM(fato_financeiro[lucro])"; P = "1. KPIs Estrategicos"; F = '$#,##0.00'; Desc = "Soma do lucro total" },
    @{ N = "Margem Bruta %"; D = "DIVIDE([Lucro Total], [Receita Total], 0)"; P = "1. KPIs Estrategicos"; F = "0.0%"; Desc = "Margem bruta percentual" },
    @{ N = "Unidades Vendidas"; D = "SUM(fato_financeiro[unidades_vendidas])"; P = "1. KPIs Estrategicos"; F = "#,##0"; Desc = "Total de unidades vendidas" },
    @{ N = "Custo Total (CPV)"; D = "SUM(fato_financeiro[custo_bens_vendidos])"; P = "1. KPIs Estrategicos"; F = '$#,##0.00'; Desc = "Custo total dos produtos vendidos" },
    @{ N = "Ticket Medio"; D = "DIVIDE([Receita Total], [Unidades Vendidas], 0)"; P = "1. KPIs Estrategicos"; F = '$#,##0.00'; Desc = "Valor medio por unidade vendida" },

    # 2. Inteligencia Temporal
    @{ N = "Crescimento MoM %"; D = "VAR Atual = [Receita Total] VAR Anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, MONTH)) RETURN DIVIDE(Atual - Anterior, Anterior, BLANK())"; P = "2. Inteligencia Temporal"; F = "0.0%"; Desc = "Crescimento mes a mes" },
    @{ N = "Receita Acumulada Ano"; D = "TOTALYTD([Receita Total], dim_tempo[data_completa])"; P = "2. Inteligencia Temporal"; F = '$#,##0.00'; Desc = "Receita acumulada YTD" },
    @{ N = "Media Movel 3 Meses"; D = "AVERAGEX(DATESINPERIOD(dim_tempo[data_completa], MAX(dim_tempo[data_completa]), -3, MONTH), [Receita Total])"; P = "2. Inteligencia Temporal"; F = '$#,##0.00'; Desc = "Media movel 3 meses" },
    @{ N = "Lucro Acumulado Ano"; D = "TOTALYTD([Lucro Total], dim_tempo[data_completa])"; P = "2. Inteligencia Temporal"; F = '$#,##0.00'; Desc = "Lucro acumulado YTD" },

    # 3. Performance Geografica
    @{ N = "Ranking Receita por Pais"; D = "RANKX(ALL(dim_geografia[pais]), [Receita Total], , DESC, DENSE)"; P = "3. Performance Geografica"; F = "0"; Desc = "Ranking receita por pais" },
    @{ N = "Ranking Lucro por Pais"; D = "RANKX(ALL(dim_geografia[pais]), [Lucro Total], , DESC, DENSE)"; P = "3. Performance Geografica"; F = "0"; Desc = "Ranking lucro por pais" },
    @{ N = "Contribuicao do Pais %"; D = "DIVIDE([Receita Total], CALCULATE([Receita Total], ALL(dim_geografia)), 0)"; P = "3. Performance Geografica"; F = "0.0%"; Desc = "Contribuicao do pais" },

    # 4. Analise por Segmento
    @{ N = "Participacao Segmento %"; D = "DIVIDE([Receita Total], CALCULATE([Receita Total], ALL(dim_segmento)), 0)"; P = "4. Analise por Segmento"; F = "0.0%"; Desc = "Participacao do segmento" },
    @{ N = "Margem Lucro Segmento %"; D = "DIVIDE([Lucro Total], [Receita Total], 0)"; P = "4. Analise por Segmento"; F = "0.0%"; Desc = "Margem de lucro por segmento" },

    # 5. Diagnostico de Descontos
    @{ N = "Total Transacoes"; D = "COUNTROWS(fato_financeiro)"; P = "5. Diagnostico de Descontos"; F = "#,##0"; Desc = "Total de transacoes" },
    @{ N = "Margem por Faixa Desconto"; D = "DIVIDE([Lucro Total], [Receita Total], 0)"; P = "5. Diagnostico de Descontos"; F = "0.0%"; Desc = "Margem por faixa de desconto" },
    @{ N = "Alerta Desconto Alto"; D = "VAR M = CALCULATE([Margem Bruta %], dim_desconto[faixa_desconto] = ""High"") RETURN IF(M < 0.10, ""ALERTA: Margem critica"", ""OK"")"; P = "5. Diagnostico de Descontos"; F = ""; Desc = "Alerta desconto alto" },

    # 6. Analise de Produto
    @{ N = "Ranking Lucro Produto"; D = "RANKX(ALL(dim_produto[produto_nome]), [Lucro Total], , DESC, DENSE)"; P = "6. Analise de Produto"; F = "0"; Desc = "Ranking de lucro por produto" },
    @{ N = "Participacao Produto %"; D = "DIVIDE([Receita Total], CALCULATE([Receita Total], ALL(dim_produto)), 0)"; P = "6. Analise de Produto"; F = "0.0%"; Desc = "Participacao do produto na receita" },
    @{ N = "Margem vs Media"; D = "VAR Atual = [Margem Bruta %] VAR Media = CALCULATE([Margem Bruta %], ALL(dim_produto)) RETURN Atual - Media"; P = "6. Analise de Produto"; F = "+0.0%;-0.0%"; Desc = "Diferenca margem vs media" },
    @{ N = "Categoria BCG"; D = "VAR CM = [Margem Bruta %] VAR CV = [Unidades Vendidas] VAR AM = CALCULATE([Margem Bruta %], ALL(dim_produto)) VAR AV = CALCULATE([Unidades Vendidas], ALL(dim_produto)) RETURN SWITCH(TRUE(), CM > AM && CV > AV, ""Estrela"", CM > AM && CV <= AV, ""Vaca Leiteira"", CM <= AM && CV > AV, ""Interrogacao"", ""Abacaxi"")"; P = "6. Analise de Produto"; F = ""; Desc = "Classificacao BCG" },

    # 7. Sazonalidade
    @{ N = "Indice Sazonalidade"; D = "VAR MS = [Receita Total] VAR MED = DIVIDE(CALCULATE([Receita Total], ALL(dim_tempo[mes])), DISTINCTCOUNT(dim_tempo[mes]), 0) RETURN DIVIDE(MS, MED, 0)"; P = "7. Sazonalidade"; F = "0.00"; Desc = "Indice de sazonalidade" },
    @{ N = "Melhor Trimestre"; D = "VAR Q1 = CALCULATE([Receita Total], dim_tempo[trimestre] = 1) VAR Q2 = CALCULATE([Receita Total], dim_tempo[trimestre] = 2) VAR Q3 = CALCULATE([Receita Total], dim_tempo[trimestre] = 3) VAR Q4 = CALCULATE([Receita Total], dim_tempo[trimestre] = 4) VAR MX = MAX(MAX(Q1, Q2), MAX(Q3, Q4)) RETURN SWITCH(MX, Q1, ""T1"", Q2, ""T2"", Q3, ""T3"", Q4, ""T4"")"; P = "7. Sazonalidade"; F = ""; Desc = "Melhor trimestre" }
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

$model.SaveChanges()
Write-Host "`n$created medidas criadas com sucesso!" -ForegroundColor Green
Write-Host "Pressione F5 no Power BI para atualizar." -ForegroundColor Cyan
$srv.Disconnect()
