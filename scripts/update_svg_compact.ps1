# === ATUALIZAR SVG Receita Total com viewBox compacto ===

# 1. Porta
$workspacesPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$workspace = Get-ChildItem -Path $workspacesPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $workspace) {
    Write-Host "ERRO: Power BI Desktop nao esta aberto." -ForegroundColor Red
    exit 1
}
$portFile = Join-Path $workspace.FullName "Data\msmdsrv.port.txt"
$port = [System.IO.File]::ReadAllText($portFile, [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''
Write-Host "Porta SSAS: $port"

# 2. DLLs
Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

# 3. Conectar
$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$model = $srv.Databases[0].Model
$targetTable = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

# 4. Atualizar medida SVG Receita Total com viewBox mais compacto (190x85)
$svgMeasure = $targetTable.Measures | Where-Object { $_.Name -eq "SVG Receita Total" }
if ($svgMeasure) {
    Write-Host "Atualizando medida 'SVG Receita Total' com viewBox compacto..."
    $svgMeasure.Expression = @"
VAR _v = [Receita Total]
VAR _m = _v / 1000000
VAR _fmt = "$" & FORMAT(_m, "#,##0.0") & "M"
VAR _ant = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_v - _ant, _ant, 0)
VAR _pctVal = ABS(_pct) * 100
VAR _pctFmt = FORMAT(_pctVal, "0.0") & "%25"
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _corS = IF(_pct >= 0, "%2310B981", "%23F43F5E")
VAR _sub = IF(ISBLANK(_ant), "sem dados", _seta & " " & _pctFmt & " vs anterior")
RETURN
"data:image/svg+xml;utf8," &
"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 190 85'>" &
"<rect width='190' height='85' rx='10' fill='%23111827' stroke='%231E293B' stroke-width='1'/>" &
"<rect y='81' width='190' height='4' rx='0 0 10 10' fill='%233B82F6'/>" &
"<text x='12' y='20' fill='%2364748B' font-size='9' font-family='Segoe UI' font-weight='600'>RECEITA TOTAL</text>" &
"<text x='12' y='50' fill='%2338BDF8' font-size='24' font-family='Segoe UI' font-weight='700'>" & _fmt & "</text>" &
"<text x='12' y='70' fill='" & _corS & "' font-size='9' font-family='Segoe UI'>" & _sub & "</text>" &
"<circle cx='168' cy='20' r='12' fill='%230F172A'/>" &
"<text x='168' y='25' fill='%233B82F6' font-size='12' font-family='Segoe UI' text-anchor='middle'>$</text>" &
"</svg>"
"@
    $model.SaveChanges()
    Write-Host "Medida SVG atualizada e salva!" -ForegroundColor Green
}
else {
    Write-Host "ERRO: Medida 'SVG Receita Total' nao encontrada." -ForegroundColor Red
}

$srv.Disconnect()
Write-Host "Concluido." -ForegroundColor Green
