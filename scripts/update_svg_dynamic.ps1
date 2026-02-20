# ============================================================================
# update_svg_dynamic.ps1
# Atualiza as medidas SVG para serem responsivas (viewBox) e corrige encoding.
# Agora o SVG preenche 100% do espaco do visual no Power BI.
# ============================================================================
$ErrorActionPreference = "Stop"

Import-Module SqlServer
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll",
    "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") |
ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$wsPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$srv = $null; $model = $null

foreach ($ws in Get-ChildItem $wsPath -Directory) {
    if (Test-Path (Join-Path $ws.FullName "Data\msmdsrv.port.txt")) {
        $port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
        try {
            $s = New-Object Microsoft.AnalysisServices.Tabular.Server
            $s.Connect("Data Source=localhost:$port")
            $db = $s.Databases[0]
            $mt = $db.Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }
            if ($mt -and $mt.Measures.Count -gt 0) {
                $srv = $s; $model = $db.Model; break
            }
            $s.Disconnect()
        }
        catch {}
    }
}

if (-not $srv) { exit 1 }

$tbl = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

# Medida base para as outras (template)
$svgTemplate = @'
VAR _v = [{0}]
VAR _m = _v / {1}
VAR _fmt = "{2}" & FORMAT(_m, "{3}") & "{4}"
VAR _ant = CALCULATE([{0}], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_v - _ant, _ant, 0)
VAR _pctVal = ABS(_pct) * 100
VAR _pctFmt = FORMAT(_pctVal, "0.0") & "%25"
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _corS = IF(_pct >= 0, "%2310B981", "%23F43F5E")
VAR _sub = IF(ISBLANK(_ant), "{5}", _seta & " " & _pctFmt & " vs anterior")
RETURN
"data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 250 110' preserveAspectRatio='xMidYMid meet'>" &
"<rect width='250' height='110' rx='12' fill='%23111827' stroke='%231E293B' stroke-width='1'/>" &
"<rect y='107' width='250' height='6' fill='{6}'/>" &
"<text x='16' y='26' fill='%2364748B' font-size='10' font-family='Segoe UI' font-weight='600'>{7}</text>" &
"<text x='16' y='65' fill='{8}' font-size='28' font-family='Segoe UI' font-weight='700'>" & _fmt & "</text>" &
"<text x='16' y='90' fill='" & _corS & "' font-size='11' font-family='Segoe UI'>" & _sub & "</text>" &
"<circle cx='222' cy='26' r='14' fill='%230F172A'/>" &
"<text x='222' y='32' fill='{6}' font-size='14' font-family='Segoe UI' text-anchor='middle'>{9}</text>" &
"</svg>"
'@

$cards = @(
    @{ N = "SVG Receita Total"; M = "Receita Total"; Div = 1e6; Pre = "$"; Post = "M"; Sub = "sem dados"; Cor = "%233B82F6"; Title = "RECEITA TOTAL"; ValCor = "%2338BDF8"; Icon = "$" },
    @{ N = "SVG Lucro Total"; M = "Lucro Total"; Div = 1e6; Pre = "$"; Post = "M"; Sub = "sem dados"; Cor = "%2310B981"; Title = "LUCRO TOTAL"; ValCor = "%2310B981"; Icon = "T" },
    @{ N = "SVG Margem Bruta"; M = "Margem Bruta %"; Div = 0.01; Pre = ""; Post = "%25"; Sub = "sem dados"; Cor = "%23F59E0B"; Title = "MARGEM BRUTA"; ValCor = "%23F59E0B"; Icon = "%" },
    @{ N = "SVG Unidades Vendidas"; M = "Unidades Vendidas"; Div = 1e6; Pre = ""; Post = "M"; Sub = "sem dados"; Cor = "%238B5CF6"; Title = "UNIDADES VENDIDAS"; ValCor = "%238B5CF6"; Icon = "#" },
    @{ N = "SVG Custo CPV"; M = "Custo Total (CPV)"; Div = 1e6; Pre = "$"; Post = "M"; Sub = "da receita"; Cor = "%23F43F5E"; Title = "CUSTO TOTAL (CPV)"; ValCor = "%23F43F5E"; Icon = "C" },
    @{ N = "SVG Ticket Medio"; M = "Ticket Medio"; Div = 1; Pre = "$"; Post = ""; Sub = "estavel"; Cor = "%2306B6D4"; Title = "TICKET MEDIO"; ValCor = "%2306B6D4"; Icon = "T" }
)

foreach ($c in $cards) {
    # Custom adjustments for specific cards
    $dax = $svgTemplate -f $c.M, $c.Div, $c.Pre, "#,##0.0", $c.Post, $c.Sub, $c.Cor, $c.Title, $c.ValCor, $c.Icon
    
    if ($c.M -eq "Margem Bruta %") {
        $dax = $dax -replace 'DATEADD', '--DATEADD' # No YoY for margin in this template
        $dax = $dax -replace '_sub = .+', '_sub = IF([Margem Bruta %]>=0.15, UNICHAR(9650) & " acima meta 15%25", UNICHAR(9660) & " abaixo meta 15%25")'
    }
    
    $m = $tbl.Measures[$c.N]
    if ($m) { $m.Expression = $dax.Trim() }
}

$model.SaveChanges()
$srv.Disconnect()
Write-Host "Medidas SVG atualizadas com viewBox e UNICHAR!" -ForegroundColor Green
