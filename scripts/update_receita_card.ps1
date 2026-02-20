# === CRIAR MEDIDA Receita YoY % E ATUALIZAR MODELO ===

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

# 4. Criar medida Receita YoY % (variacao ano a ano)
$existingYoY = $targetTable.Measures | Where-Object { $_.Name -eq "Receita YoY %" }
if ($existingYoY) {
    Write-Host "Medida 'Receita YoY %' ja existe. Atualizando..."
    $existingYoY.Expression = @"
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
RETURN
    DIVIDE(_atual - _anterior, _anterior, BLANK())
"@
    $existingYoY.FormatString = "0.0%;-0.0%;0.0%"
    $existingYoY.DisplayFolder = "1. KPIs Estrategicos"
    $existingYoY.Description = "Variacao percentual da receita total em comparacao ao ano anterior (YoY)"
}
else {
    Write-Host "Criando medida 'Receita YoY %'..."
    $measure = New-Object Microsoft.AnalysisServices.Tabular.Measure
    $measure.Name = "Receita YoY %"
    $measure.Expression = @"
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
RETURN
    DIVIDE(_atual - _anterior, _anterior, BLANK())
"@
    $measure.FormatString = "0.0%;-0.0%;0.0%"
    $measure.DisplayFolder = "1. KPIs Estrategicos"
    $measure.Description = "Variacao percentual da receita total em comparacao ao ano anterior (YoY)"
    $targetTable.Measures.Add($measure)
}

# 5. Criar medida auxiliar para texto do subtitulo do cartao
$existingSubtitle = $targetTable.Measures | Where-Object { $_.Name -eq "Receita YoY Texto" }
if ($existingSubtitle) {
    Write-Host "Medida 'Receita YoY Texto' ja existe. Atualizando..."
    $existingSubtitle.Expression = @"
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs ano anterior")
"@
    $existingSubtitle.DisplayFolder = "1. KPIs Estrategicos"
    $existingSubtitle.Description = "Texto formatado de variacao YoY para exibir no subtitulo do cartao"
}
else {
    Write-Host "Criando medida 'Receita YoY Texto'..."
    $measure2 = New-Object Microsoft.AnalysisServices.Tabular.Measure
    $measure2.Name = "Receita YoY Texto"
    $measure2.Expression = @"
VAR _atual = [Receita Total]
VAR _anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR))
VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK())
VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660))
VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%"
RETURN
    IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs ano anterior")
"@
    $measure2.DisplayFolder = "1. KPIs Estrategicos"
    $measure2.Description = "Texto formatado de variacao YoY para exibir no subtitulo do cartao"
    $targetTable.Measures.Add($measure2)
}

# 6. Salvar
$model.SaveChanges()
Write-Host "`nModelo salvo com sucesso!" -ForegroundColor Green

# 7. Listar medidas atualizadas
Write-Host "`nMedidas atuais (KPIs Estrategicos):"
$targetTable.Measures | Where-Object { $_.DisplayFolder -eq "1. KPIs Estrategicos" } | ForEach-Object {
    Write-Host "  - $($_.Name): $($_.Expression.Substring(0, [Math]::Min(60, $_.Expression.Length)))..."
}

$srv.Disconnect()
Write-Host "`nConcluido." -ForegroundColor Green
