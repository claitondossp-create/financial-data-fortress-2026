# ============================================================================
# create_svg_kpis.ps1
# Cria 6 medidas DAX que retornam SVG dinamico para KPI cards no Power BI.
# O SVG inclui: titulo, valor formatado, comparacao YoY e icone.
# Tudo atualiza automaticamente quando filtros/slicers mudam.
# ============================================================================
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " CRIANDO KPI CARDS SVG DINAMICOS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Import-Module SqlServer
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll",
    "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") |
ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

# Encontrar workspace ativo
$wsPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$srv = $null
$model = $null

foreach ($ws in Get-ChildItem $wsPath -Directory) {
    $pf = Join-Path $ws.FullName "Data\msmdsrv.port.txt"
    if (Test-Path $pf) {
        $port = [System.IO.File]::ReadAllText($pf, [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
        try {
            $s = New-Object Microsoft.AnalysisServices.Tabular.Server
            $s.Connect("Data Source=localhost:$port")
            $db = $s.Databases[0]
            $mt = $db.Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }
            if ($mt -and $mt.Measures.Count -gt 0) {
                $srv = $s; $model = $db.Model
                Write-Host "  Conectado porta $port" -ForegroundColor Green
                break
            }
            $s.Disconnect()
        }
        catch {}
    }
}

if (-not $srv) { Write-Host "ERRO: modelo nao encontrado" -ForegroundColor Red; exit 1 }

$tbl = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

# Remover SVG cards antigos (se existirem)
$svgNames = @($tbl.Measures | Where-Object { $_.DisplayFolder -eq "0. SVG Cards" } | ForEach-Object { $_.Name })
foreach ($n in $svgNames) {
    $m = $tbl.Measures[$n]
    if ($m) { $tbl.Measures.Remove($m) | Out-Null }
}
if ($svgNames.Count -gt 0) { Write-Host "  $($svgNames.Count) SVG cards antigos removidos" -ForegroundColor Yellow }

# ================================================================
# DEFINICOES DOS 6 KPI SVG CARDS
# ================================================================

$svgCards = @()

# --- 1. RECEITA TOTAL ---
$svgCards += @{
    Name = "SVG Receita Total"
    Desc = "Card SVG dinamico para Receita Total com comparacao YoY"
    DAX  = @'
VAR _v = [Receita Total]
VAR _m = _v / 1000000
VAR _fmt = "$" & FORMAT(_m, "#,##0.0") & "M"
VAR _ant = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_v - _ant, _ant, 0)
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%25"
VAR _seta = IF(_pct >= 0, "▲ ", "▼ ")
VAR _corS = IF(_pct >= 0, "%2310B981", "%23F43F5E")
VAR _sub = IF(ISBLANK(_ant), "sem dados anteriores", _seta & _pctFmt & " vs anterior")
RETURN
"data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='250' height='110'>" &
"<rect width='250' height='110' rx='12' fill='%23111827' stroke='%231E293B' stroke-width='1'/>" &
"<rect y='107' width='250' height='3' fill='%233B82F6'/>" &
"<text x='16' y='26' fill='%2364748B' font-size='10' font-family='Segoe UI' font-weight='600'>RECEITA TOTAL</text>" &
"<text x='16' y='60' fill='%2338BDF8' font-size='26' font-family='Segoe UI' font-weight='700'>" & _fmt & "</text>" &
"<text x='16' y='85' fill='" & _corS & "' font-size='10' font-family='Segoe UI'>" & _sub & "</text>" &
"<circle cx='222' cy='26' r='14' fill='%230F172A'/>" &
"<text x='222' y='31' fill='%233B82F6' font-size='14' font-family='Segoe UI' text-anchor='middle'>$</text>" &
"</svg>"
'@
}

# --- 2. LUCRO TOTAL ---
$svgCards += @{
    Name = "SVG Lucro Total"
    Desc = "Card SVG dinamico para Lucro Total com comparacao YoY"
    DAX  = @'
VAR _v = [Lucro Total]
VAR _m = _v / 1000000
VAR _fmt = "$" & FORMAT(_m, "#,##0.0") & "M"
VAR _ant = CALCULATE([Lucro Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_v - _ant, _ant, 0)
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%25"
VAR _seta = IF(_pct >= 0, "▲ ", "▼ ")
VAR _corS = IF(_pct >= 0, "%2310B981", "%23F43F5E")
VAR _sub = IF(ISBLANK(_ant), "sem dados anteriores", _seta & _pctFmt & " vs anterior")
RETURN
"data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='250' height='110'>" &
"<rect width='250' height='110' rx='12' fill='%23111827' stroke='%231E293B' stroke-width='1'/>" &
"<rect y='107' width='250' height='3' fill='%2310B981'/>" &
"<text x='16' y='26' fill='%2364748B' font-size='10' font-family='Segoe UI' font-weight='600'>LUCRO TOTAL</text>" &
"<text x='16' y='60' fill='%2310B981' font-size='26' font-family='Segoe UI' font-weight='700'>" & _fmt & "</text>" &
"<text x='16' y='85' fill='" & _corS & "' font-size='10' font-family='Segoe UI'>" & _sub & "</text>" &
"<circle cx='222' cy='26' r='14' fill='%230F172A'/>" &
"<text x='222' y='31' fill='%2310B981' font-size='14' font-family='Segoe UI' text-anchor='middle'>↑</text>" &
"</svg>"
'@
}

# --- 3. MARGEM BRUTA % ---
$svgCards += @{
    Name = "SVG Margem Bruta"
    Desc = "Card SVG dinamico para Margem Bruta vs meta 15%"
    DAX  = @'
VAR _v = [Margem Bruta %]
VAR _fmt = FORMAT(_v * 100, "0.0") & "%25"
VAR _meta = 0.15
VAR _diff = (_v - _meta) * 100
VAR _diffFmt = FORMAT(ABS(_diff), "0.0") & "pp"
VAR _seta = IF(_diff >= 0, "▲ ", "▼ ")
VAR _corS = IF(_diff >= 0, "%2310B981", "%23F43F5E")
VAR _sub = _seta & _diffFmt & " vs meta 15%25"
RETURN
"data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='250' height='110'>" &
"<rect width='250' height='110' rx='12' fill='%23111827' stroke='%231E293B' stroke-width='1'/>" &
"<rect y='107' width='250' height='3' fill='%23F59E0B'/>" &
"<text x='16' y='26' fill='%2364748B' font-size='10' font-family='Segoe UI' font-weight='600'>MARGEM BRUTA</text>" &
"<text x='16' y='60' fill='%23F59E0B' font-size='26' font-family='Segoe UI' font-weight='700'>" & _fmt & "</text>" &
"<text x='16' y='85' fill='" & _corS & "' font-size='10' font-family='Segoe UI'>" & _sub & "</text>" &
"<circle cx='222' cy='26' r='14' fill='%230F172A'/>" &
"<text x='222' y='31' fill='%23F59E0B' font-size='14' font-family='Segoe UI' text-anchor='middle'>%25</text>" &
"</svg>"
'@
}

# --- 4. UNIDADES VENDIDAS ---
$svgCards += @{
    Name = "SVG Unidades Vendidas"
    Desc = "Card SVG dinamico para Unidades Vendidas com comparacao YoY"
    DAX  = @'
VAR _v = [Unidades Vendidas]
VAR _fmt = IF(_v >= 1000000, FORMAT(_v / 1000000, "#,##0.00") & "M", IF(_v >= 1000, FORMAT(_v / 1000, "#,##0.0") & "K", FORMAT(_v, "#,##0")))
VAR _ant = CALCULATE([Unidades Vendidas], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_v - _ant, _ant, 0)
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%25"
VAR _seta = IF(_pct >= 0, "▲ ", "▼ ")
VAR _corS = IF(_pct >= 0, "%2310B981", "%23F43F5E")
VAR _sub = IF(ISBLANK(_ant), "sem dados anteriores", _seta & _pctFmt & " vs anterior")
RETURN
"data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='250' height='110'>" &
"<rect width='250' height='110' rx='12' fill='%23111827' stroke='%231E293B' stroke-width='1'/>" &
"<rect y='107' width='250' height='3' fill='%238B5CF6'/>" &
"<text x='16' y='26' fill='%2364748B' font-size='10' font-family='Segoe UI' font-weight='600'>UNIDADES VENDIDAS</text>" &
"<text x='16' y='60' fill='%238B5CF6' font-size='26' font-family='Segoe UI' font-weight='700'>" & _fmt & "</text>" &
"<text x='16' y='85' fill='" & _corS & "' font-size='10' font-family='Segoe UI'>" & _sub & "</text>" &
"<circle cx='222' cy='26' r='14' fill='%230F172A'/>" &
"<text x='222' y='31' fill='%238B5CF6' font-size='14' font-family='Segoe UI' text-anchor='middle'>#</text>" &
"</svg>"
'@
}

# --- 5. CUSTO TOTAL (CPV) ---
$svgCards += @{
    Name = "SVG Custo CPV"
    Desc = "Card SVG dinamico para Custo Total mostrando % da receita"
    DAX  = @'
VAR _v = [Custo Total (CPV)]
VAR _m = _v / 1000000
VAR _fmt = "$" & FORMAT(_m, "#,##0.0") & "M"
VAR _rec = [Receita Total]
VAR _pctRec = DIVIDE(_v, _rec, 0)
VAR _pctFmt = FORMAT(_pctRec * 100, "0.0") & "%25"
VAR _sub = _pctFmt & " da receita"
RETURN
"data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='250' height='110'>" &
"<rect width='250' height='110' rx='12' fill='%23111827' stroke='%231E293B' stroke-width='1'/>" &
"<rect y='107' width='250' height='3' fill='%23F43F5E'/>" &
"<text x='16' y='26' fill='%2364748B' font-size='10' font-family='Segoe UI' font-weight='600'>CUSTO TOTAL (CPV)</text>" &
"<text x='16' y='60' fill='%23F43F5E' font-size='26' font-family='Segoe UI' font-weight='700'>" & _fmt & "</text>" &
"<text x='16' y='85' fill='%2364748B' font-size='10' font-family='Segoe UI'>" & _sub & "</text>" &
"<circle cx='222' cy='26' r='14' fill='%230F172A'/>" &
"<text x='222' y='31' fill='%23F43F5E' font-size='14' font-family='Segoe UI' text-anchor='middle'>C</text>" &
"</svg>"
'@
}

# --- 6. TICKET MEDIO ---
$svgCards += @{
    Name = "SVG Ticket Medio"
    Desc = "Card SVG dinamico para Ticket Medio com comparacao YoY"
    DAX  = @'
VAR _v = [Ticket Medio]
VAR _fmt = "$" & FORMAT(_v, "#,##0.00")
VAR _ant = CALCULATE([Ticket Medio], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_v - _ant, _ant, 0)
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%25"
VAR _seta = IF(_pct >= 0, "▲ ", "▼ ")
VAR _corS = IF(_pct >= 0, "%2310B981", "%23F43F5E")
VAR _sub = IF(ISBLANK(_ant), "estavel", _seta & _pctFmt & " vs anterior")
RETURN
"data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' width='250' height='110'>" &
"<rect width='250' height='110' rx='12' fill='%23111827' stroke='%231E293B' stroke-width='1'/>" &
"<rect y='107' width='250' height='3' fill='%2306B6D4'/>" &
"<text x='16' y='26' fill='%2364748B' font-size='10' font-family='Segoe UI' font-weight='600'>TICKET MEDIO</text>" &
"<text x='16' y='60' fill='%2306B6D4' font-size='26' font-family='Segoe UI' font-weight='700'>" & _fmt & "</text>" &
"<text x='16' y='85' fill='" & _corS & "' font-size='10' font-family='Segoe UI'>" & _sub & "</text>" &
"<circle cx='222' cy='26' r='14' fill='%230F172A'/>" &
"<text x='222' y='31' fill='%2306B6D4' font-size='14' font-family='Segoe UI' text-anchor='middle'>T</text>" &
"</svg>"
'@
}

# ================================================================
# CRIAR MEDIDAS NO MODELO
# ================================================================

$created = 0
foreach ($card in $svgCards) {
    try {
        $measure = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $measure.Name = $card.Name
        $measure.Expression = $card.DAX.Trim()
        $measure.Description = $card.Desc
        $measure.DisplayFolder = "0. SVG Cards"
        $measure.IsHidden = $false
        $tbl.Measures.Add($measure)
        Write-Host "  [OK] $($card.Name)" -ForegroundColor Green
        $created++
    }
    catch {
        Write-Host "  [ERRO] $($card.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

$model.SaveChanges()
Write-Host "`n$created SVG cards criados!" -ForegroundColor Green

Write-Host ""
Write-Host "=== COMO USAR NO POWER BI ===" -ForegroundColor Cyan
Write-Host "1. Pressione F5 para atualizar" -ForegroundColor White
Write-Host "2. Insira um visual 'Tabela'" -ForegroundColor White
Write-Host "3. Arraste 'SVG Receita Total' para Valores" -ForegroundColor White
Write-Host "4. No painel Formato > Cell elements > Image:" -ForegroundColor White
Write-Host "   - Ative 'Image URL'" -ForegroundColor White
Write-Host "   - Image sizing: Fit" -ForegroundColor White
Write-Host "5. Oculte cabecalho de coluna e bordas" -ForegroundColor White
Write-Host "6. Repita para os outros 5 SVG cards" -ForegroundColor White

$srv.Disconnect()
