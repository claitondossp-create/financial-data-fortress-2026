# === CRIAR MEDIDAS DE SUBTITULO PARA TODOS OS 6 KPIs ===

# 1. Porta
$workspacesPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$workspace = Get-ChildItem -Path $workspacesPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $workspace) { Write-Host "ERRO: Power BI Desktop nao aberto." -ForegroundColor Red; exit 1 }
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
$tbl = $model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

# 4. Definir medidas de subtitulo
$measures = @(
    @{
        Name       = "Lucro YoY Texto"
        Expression = 'VAR _atual = [Lucro Total] VAR _anterior = CALCULATE([Lucro Total], DATEADD(dim_tempo[data_completa], -1, YEAR)) VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK()) VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660)) VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%" RETURN IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs ano anterior")'
        Folder     = "1. KPIs Estrategicos"
    },
    @{
        Name       = "Margem Bruta Subtitulo"
        Expression = 'VAR _atual = [Margem Bruta %] VAR _meta = 0.15 VAR _diff = (_atual - _meta) * 100 VAR _seta = IF(_diff >= 0, UNICHAR(9650), UNICHAR(9660)) VAR _diffFmt = FORMAT(ABS(_diff), "0.0") & "pp" RETURN _seta & " " & _diffFmt & " vs meta 15%"'
        Folder     = "1. KPIs Estrategicos"
    },
    @{
        Name       = "Unidades Vendidas Subtitulo"
        Expression = 'VAR _atual = [Unidades Vendidas] VAR _anterior = CALCULATE([Unidades Vendidas], DATEADD(dim_tempo[data_completa], -1, YEAR)) VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK()) VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660)) VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%" RETURN IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " crescimento")'
        Folder     = "1. KPIs Estrategicos"
    },
    @{
        Name       = "Custo CPV Subtitulo"
        Expression = 'VAR _pct = DIVIDE([Custo Total (CPV)], [Receita Total], 0) VAR _pctFmt = FORMAT(_pct * 100, "0.0") & "%" RETURN _pctFmt & " da receita"'
        Folder     = "1. KPIs Estrategicos"
    },
    @{
        Name       = "Ticket Medio Subtitulo"
        Expression = 'VAR _atual = [Ticket Medio] VAR _anterior = CALCULATE([Ticket Medio], DATEADD(dim_tempo[data_completa], -1, YEAR)) VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK()) VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660)) RETURN IF(ISBLANK(_anterior), "sem dados", IF(ABS(_pct) < 0.01, _seta & " estavel", _seta & " " & FORMAT(ABS(_pct) * 100, "0.0") & "% vs anterior"))'
        Folder     = "1. KPIs Estrategicos"
    }
)

foreach ($m in $measures) {
    $existing = $tbl.Measures | Where-Object { $_.Name -eq $m.Name }
    if ($existing) {
        Write-Host "Atualizando: $($m.Name)" -ForegroundColor Yellow
        $existing.Expression = $m.Expression
        $existing.DisplayFolder = $m.Folder
    }
    else {
        Write-Host "Criando: $($m.Name)" -ForegroundColor Green
        $newM = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $newM.Name = $m.Name
        $newM.Expression = $m.Expression
        $newM.DisplayFolder = $m.Folder
        $tbl.Measures.Add($newM)
    }
}

# 5. Verificar Receita YoY Texto existe
$ryoy = $tbl.Measures | Where-Object { $_.Name -eq "Receita YoY Texto" }
if ($ryoy) {
    Write-Host "Receita YoY Texto: OK" -ForegroundColor Green
}
else {
    Write-Host "Criando Receita YoY Texto" -ForegroundColor Green
    $newM = New-Object Microsoft.AnalysisServices.Tabular.Measure
    $newM.Name = "Receita YoY Texto"
    $newM.Expression = 'VAR _atual = [Receita Total] VAR _anterior = CALCULATE([Receita Total], DATEADD(dim_tempo[data_completa], -1, YEAR)) VAR _pct = DIVIDE(_atual - _anterior, _anterior, BLANK()) VAR _seta = IF(_pct >= 0, UNICHAR(9650), UNICHAR(9660)) VAR _pctFmt = FORMAT(ABS(_pct) * 100, "0.0") & "%" RETURN IF(ISBLANK(_anterior), "sem dados", _seta & " " & _pctFmt & " vs ano anterior")'
    $newM.DisplayFolder = "1. KPIs Estrategicos"
    $tbl.Measures.Add($newM)
}

# 6. Salvar
$model.SaveChanges()
Write-Host "`nTodas as medidas salvas!" -ForegroundColor Green

# 7. Listar
$tbl.Measures | Where-Object { $_.Name -like "*Subtitulo*" -or $_.Name -like "*YoY*" -or $_.Name -like "*Texto*" } | ForEach-Object {
    Write-Host "  => $($_.Name)"
}

$srv.Disconnect()
Write-Host "Concluido!" -ForegroundColor Green
