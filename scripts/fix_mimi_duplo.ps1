# === DESLIGANDO AUTO-SCALE DOS VISUAIS COM 'Mi Mi' E CORRIGINDO FORMAT STRING PT-BR ===

# 1. Ajustando a Format String no Modelo Tabular
$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

$targetMeasures = @("Receita Total", "Lucro Total", "Custo Total (CPV)", "Receita Acumulada Ano", "Lucro Acumulado Ano")
# Formato pt-BR perfeito: Ponto para milhares, Virgula para decimal, Dois Pontos ".." para escalar Milhoes
$brFormat = '"R$ "#.##0,0.. "Mi";-"R$ "#.##0,0.. "Mi"'

foreach ($m in $tbl.Measures) {
    if ($targetMeasures -contains $m.Name) {
        $m.FormatString = $brFormat
        Write-Host "FormatString pt-BR Aplicada: $($m.Name)" -ForegroundColor Green
    }
}
$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()


# 2. Varredura no Front-end JSON para travar a Unidade de Exibicao em 'Nenhum' (1D)
Write-Host "Modificando visual.json para desativar Auto-Scaling (Evitar 'Mi Mi')..." -ForegroundColor Cyan

$baseDir = "C:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\Financeiro.Report\definition\pages"
$files = Get-ChildItem -Path $baseDir -Filter "visual.json" -Recurse

# Uma funcao recursiva robusta iterando sobre o Hashtable (PSObject) e apagando ou editando labelDisplayUnits
foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    
    # Se contiver labelDisplayUnits ou valueAxis/displayUnits (para graficos)
    $modified = $false
    
    # Substituicao bruta de Regex para evitar estropiar JSON profundos
    # labelDisplayUnits... "Value": "0D" -> "Value": "1D"
    if ($content -match '"labelDisplayUnits":\s*\{\s*"expr":\s*\{\s*"Literal":\s*\{\s*"Value":\s*"0D"\s*\}\s*\}\s*\}') {
        $content = $content -replace '("labelDisplayUnits":\s*\{\s*"expr":\s*\{\s*"Literal":\s*\{\s*"Value":\s*)"0D"(\s*\}\s*\}\s*\})', '${1}"1D"$2'
        $modified = $true
    }

    # displayUnits no eixo valor (LineChart)
    if ($content -match '"displayUnits":\s*\{\s*"expr":\s*\{\s*"Literal":\s*\{\s*"Value":\s*"0D"\s*\}\s*\}\s*\}') {
        $content = $content -replace '("displayUnits":\s*\{\s*"expr":\s*\{\s*"Literal":\s*\{\s*"Value":\s*)"0D"(\s*\}\s*\}\s*\})', '${1}"1D"$2'
        $modified = $true
    }

    if ($modified) {
        Set-Content -Path $f.FullName -Value $content -Encoding UTF8
        Write-Host "Alterado: $($f.FullName)" -ForegroundColor Yellow
    }
}

Write-Host "Patch Definitivo de UX Finalizado."
