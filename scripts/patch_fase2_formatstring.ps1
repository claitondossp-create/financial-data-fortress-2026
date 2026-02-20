# === APLICANDO DATA-INK RATIO E FORMAT STRING (FASE 2) ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$db = $srv.Databases[0]
$tbl = $db.Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

Write-Host "Iniciando injecao de FormatString em Milhoes (Data-Ink Ratio)..." -ForegroundColor Cyan

$report = @()

$targetMeasures = @("Receita Total", "Lucro Total", "Custo Total (CPV)", "Receita Acumulada Ano", "Lucro Acumulado Ano")
$milhoesFormat = '\"R$ \"#,##0.0,, \"Mi\";-\"R$ \"#,##0.0,, \"Mi\"'

foreach ($m in $tbl.Measures) {
    $oldFormat = $m.FormatString
    $newFormat = $oldFormat

    # 1. Aplicar o formato "Declutter" de Milhoes (Tufte) nas principais
    if ($targetMeasures -contains $m.Name) {
        $newFormat = '\"R$ \"#,##0.0,, \"Mi\";-\"R$ \"#,##0.0,, \"Mi\"'
        
        # Limpar o FormatStringExpression (Dynamic Format String) se existir, 
        # para que o FormatString estático predomine nesta arquitetura.
        if ($m.FormatStringExpression) {
            $m.FormatStringExpression = ""
        }
    } 
    else {
        # 2. Varredura global: Find and Replace para corrigir RS / $ mal formatado
        if ($newFormat -match "RS\s?" -or $newFormat -match "\\\$") {
            $newFormat = $newFormat -replace 'RS\s?', '\"R$ \"'
            $newFormat = $newFormat -replace '\\\$', '\"R$ \"'
        }
    }

    if ($oldFormat -ne $newFormat) {
        $m.FormatString = $newFormat
        $report += [PSCustomObject]@{
            Medida         = $m.Name
            Formato_Antigo = $oldFormat
            Novo_Formato   = $newFormat
        }
    }
}

$db.Model.SaveChanges()
$srv.Disconnect()

# Exportar relatorio em tabela Markdown
Write-Host ""
Write-Host "| Nome da Medida | Formato Antigo | Nova Format String (Aplicada) |"
Write-Host "|----------------|----------------|-------------------------------|"
foreach ($r in $report) {
    Write-Host "| $($r.Medida) | $($r.Formato_Antigo) | $($r.Novo_Formato) |"
}
Write-Host "`nFase 2 (Data-Ink FormatString) concluida com sucesso!" -ForegroundColor Green
