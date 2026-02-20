# === SCRIPT DE INSTRUCAO E MAPEAMENTO (COTD) ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$db = $srv.Databases[0]

$report = @{
    Tabelas_Analisadas         = @()
    Renomeacao_Produto_A_Fazer = @()
    Encoding_Erros_Encontrados = @()
    Chaves_Tecnicas_A_Ocultar  = @()
}

foreach ($t in $db.Model.Tables) {
    $report.Tabelas_Analisadas += $t.Name

    foreach ($c in $t.Columns) {
        # 1. Checar colunas de Produto
        if ($t.Name -match "produto" -or $t.Name -eq "dim_produto") {
            if ($c.Name -match "produto(_|\s)?sk" -or $c.Name -match "produto(_|\s)?nome") {
                $report.Renomeacao_Produto_A_Fazer += @{
                    Tabela          = $t.Name
                    ColunaAtual     = $c.Name
                    AcaoRecomendada = if ($c.Name -match "sk") { "Renomear para 'Código do Produto'" } else { "Renomear para 'Produto'" }
                }
            }
        }

        # 2. Checar Encoding (PaÅs, etc)
        if ($c.Name -match "PaÅs|PaAs|PaÃs|Pa.s" -and $c.Name -ne "País" -and $c.Name -ne "pais") {
            $report.Encoding_Erros_Encontrados += @{
                Tabela          = $t.Name
                ColunaAtual     = $c.Name
                AcaoRecomendada = "Renomear para 'País'"
            }
        }

        # 3. Checar colunas tecnicas visiveis (terminadas em _sk, _key, id)
        if (($c.Name -match "_sk$" -or $c.Name -match "_key$" -or $c.Name -match "id$") -and ($c.IsHidden -eq $false)) {
            $report.Chaves_Tecnicas_A_Ocultar += @{
                Tabela          = $t.Name
                ColunaAtual     = $c.Name
                AcaoRecomendada = "Aplicar IsHidden = true"
            }
        }
    }
}

$srv.Disconnect()

# Exportar relatorio
$reportJson = $report | ConvertTo-Json -Depth 5
Write-Output $reportJson
