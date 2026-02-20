# ============================================================================
# create_pbi_report.ps1
# Cria um projeto PBIP (Power BI Project) com modelo + relatório pré-montado
# contendo a página "Visão Estratégica Executiva" com todos os visuais.
# ============================================================================
$ErrorActionPreference = "Stop"

$projectRoot = "c:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\powerbi"
$projectName = "Financial_Fortress"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " CRIANDO PROJETO POWER BI (PBIP)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# --- 1. Conectar e Exportar Modelo ---
Write-Host "`n[1/4] Exportando modelo do SSAS..." -ForegroundColor Yellow

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll",
    "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") |
ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText("$($ws.FullName)\Data\msmdsrv.port.txt", [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$db = $srv.Databases[0]
$bim = [Microsoft.AnalysisServices.Tabular.JsonSerializer]::SerializeDatabase($db)
$srv.Disconnect()
Write-Host "  Modelo exportado ($($bim.Length) chars)" -ForegroundColor Green

# --- 2. Criar Estrutura de Diretórios ---
Write-Host "`n[2/4] Criando estrutura PBIP..." -ForegroundColor Yellow

$datasetDir = "$projectRoot\$projectName.Dataset"
$reportDir = "$projectRoot\$projectName.Report"
New-Item -Path $datasetDir -ItemType Directory -Force | Out-Null
New-Item -Path $reportDir  -ItemType Directory -Force | Out-Null

# .pbip
$pbip = @{
    version   = "1.0"
    artifacts = @(
        @{ report = @{ path = "$projectName.Report" } }
    )
    settings  = @{ enableAutoRecovery = $true }
} | ConvertTo-Json -Depth 5

[System.IO.File]::WriteAllText("$projectRoot\$projectName.pbip", $pbip, [System.Text.Encoding]::UTF8)

# Dataset files
[System.IO.File]::WriteAllText("$datasetDir\model.bim", $bim, [System.Text.Encoding]::UTF8)

$dsDefinition = '{"version": "1.0", "settings": {}}'
[System.IO.File]::WriteAllText("$datasetDir\definition.pbidataset", $dsDefinition, [System.Text.Encoding]::UTF8)

# Report definition
$rptDef = @{
    version          = "4.0"
    datasetReference = @{
        byPath       = @{ path = "../$projectName.Dataset" }
        byConnection = $null
    }
} | ConvertTo-Json -Depth 5

[System.IO.File]::WriteAllText("$reportDir\definition.pbireport", $rptDef, [System.Text.Encoding]::UTF8)

Write-Host "  Estrutura criada." -ForegroundColor Green

# --- 3. Construir Layout do Relatório ---
Write-Host "`n[3/4] Construindo layout com visuais..." -ForegroundColor Yellow

# Helper: cria config de visual tipo Card (medida)
function New-CardConfig($name, $measureName) {
    return @{
        name         = $name
        layouts      = @(@{ id = 0; position = @{ x = 0; y = 0; width = 0; height = 0 } })
        singleVisual = @{
            visualType     = "card"
            projections    = @{ Values = @(@{ queryRef = "Medidas Insights.$measureName"; active = $true }) }
            prototypeQuery = @{
                Version = 2
                From    = @(@{ Name = "m"; Entity = "Medidas Insights"; Type = 0 })
                Select  = @(
                    @{
                        Measure = @{
                            Expression = @{ SourceRef = @{ Source = "m" } }
                            Property   = $measureName
                        }
                        Name    = "Medidas Insights.$measureName"
                    }
                )
            }
        }
    }
}

# Helper: cria config de visual com Category + Measure
function New-ChartConfig($name, $visType, $catEntity, $catAlias, $catProp, $catRole, $valRole, $measures) {
    $from = @(
        @{ Name = $catAlias; Entity = $catEntity; Type = 0 }
        @{ Name = "m"; Entity = "Medidas Insights"; Type = 0 }
    )
    $select = @(
        @{
            Column = @{
                Expression = @{ SourceRef = @{ Source = $catAlias } }
                Property   = $catProp
            }
            Name   = "$catEntity.$catProp"
        }
    )
    $catProjections = @(@{ queryRef = "$catEntity.$catProp"; active = $true })
    $valProjections = @()

    foreach ($msr in $measures) {
        $select += @{
            Measure = @{
                Expression = @{ SourceRef = @{ Source = "m" } }
                Property   = $msr
            }
            Name    = "Medidas Insights.$msr"
        }
        $valProjections += @{ queryRef = "Medidas Insights.$msr"; active = $true }
    }

    $projections = @{}
    $projections[$catRole] = $catProjections
    $projections[$valRole] = $valProjections

    return @{
        name         = $name
        layouts      = @(@{ id = 0; position = @{ x = 0; y = 0; width = 0; height = 0 } })
        singleVisual = @{
            visualType     = $visType
            projections    = $projections
            prototypeQuery = @{ Version = 2; From = $from; Select = $select }
        }
    }
}

# Define visuais e posições (canvas 1280x720)
$visuals = @()

# --- KPI Cards (6) ---
$kpiMeasures = @("Receita Total", "Lucro Total", "Margem Bruta %", "Unidades Vendidas", "Custo Total (CPV)", "Ticket Medio")
for ($i = 0; $i -lt $kpiMeasures.Count; $i++) {
    $cfg = New-CardConfig "card_$i" $kpiMeasures[$i]
    $visuals += @{
        x = 18 + ($i * 208); y = 65; z = ($i + 1); width = 196; height = 95
        config = $cfg
    }
}

# --- Line Chart: Receita vs Lucro por Mês ---
$lineChart = New-ChartConfig "lineChart_temporal" "lineChart" "dim_tempo" "t" "data_completa" "Category" "Y" @("Receita Total", "Lucro Total")
$visuals += @{ x = 18; y = 175; z = 10; width = 618; height = 260; config = $lineChart }

# --- Clustered Bar Chart: Receita por País ---
$barChart = New-ChartConfig "barChart_pais" "clusteredBarChart" "dim_geografia" "g" "pais" "Category" "Y" @("Receita Total", "Lucro Total")
$visuals += @{ x = 650; y = 175; z = 11; width = 612; height = 260; config = $barChart }

# --- Donut Chart: Segmentos ---
$donut = New-ChartConfig "donut_segmento" "donutChart" "dim_segmento" "s" "nome_segmento" "Category" "Y" @("Receita Total")
$visuals += @{ x = 18; y = 450; z = 12; width = 618; height = 255; config = $donut }

# --- Table: Ranking Produtos ---
$tableCfg = @{
    name         = "table_produtos"
    layouts      = @(@{ id = 0; position = @{ x = 0; y = 0; width = 0; height = 0 } })
    singleVisual = @{
        visualType     = "tableEx"
        projections    = @{
            Values = @(
                @{ queryRef = "dim_produto.nome_produto"; active = $true }
                @{ queryRef = "Medidas Insights.Receita Total"; active = $true }
                @{ queryRef = "Medidas Insights.Lucro Total"; active = $true }
                @{ queryRef = "Medidas Insights.Margem Bruta %"; active = $true }
                @{ queryRef = "Medidas Insights.Unidades Vendidas"; active = $true }
            )
        }
        prototypeQuery = @{
            Version = 2
            From    = @(
                @{ Name = "p"; Entity = "dim_produto"; Type = 0 }
                @{ Name = "m"; Entity = "Medidas Insights"; Type = 0 }
            )
            Select  = @(
                @{ Column = @{ Expression = @{ SourceRef = @{ Source = "p" } }; Property = "nome_produto" }; Name = "dim_produto.nome_produto" }
                @{ Measure = @{ Expression = @{ SourceRef = @{ Source = "m" } }; Property = "Receita Total" }; Name = "Medidas Insights.Receita Total" }
                @{ Measure = @{ Expression = @{ SourceRef = @{ Source = "m" } }; Property = "Lucro Total" }; Name = "Medidas Insights.Lucro Total" }
                @{ Measure = @{ Expression = @{ SourceRef = @{ Source = "m" } }; Property = "Margem Bruta %" }; Name = "Medidas Insights.Margem Bruta %" }
                @{ Measure = @{ Expression = @{ SourceRef = @{ Source = "m" } }; Property = "Unidades Vendidas" }; Name = "Medidas Insights.Unidades Vendidas" }
            )
        }
    }
}
$visuals += @{ x = 650; y = 450; z = 13; width = 612; height = 255; config = $tableCfg }

# --- Slicer: Ano ---
$slicerYear = @{
    name         = "slicer_ano"
    layouts      = @(@{ id = 0; position = @{ x = 0; y = 0; width = 0; height = 0 } })
    singleVisual = @{
        visualType     = "slicer"
        projections    = @{ Values = @(@{ queryRef = "dim_tempo.ano"; active = $true }) }
        prototypeQuery = @{
            Version = 2
            From    = @(@{ Name = "t"; Entity = "dim_tempo"; Type = 0 })
            Select  = @(@{ Column = @{ Expression = @{ SourceRef = @{ Source = "t" } }; Property = "ano" }; Name = "dim_tempo.ano" })
        }
    }
}
$visuals += @{ x = 18; y = 8; z = 20; width = 180; height = 48; config = $slicerYear }

# --- Slicer: País ---
$slicerPais = @{
    name         = "slicer_pais"
    layouts      = @(@{ id = 0; position = @{ x = 0; y = 0; width = 0; height = 0 } })
    singleVisual = @{
        visualType     = "slicer"
        projections    = @{ Values = @(@{ queryRef = "dim_geografia.pais"; active = $true }) }
        prototypeQuery = @{
            Version = 2
            From    = @(@{ Name = "g"; Entity = "dim_geografia"; Type = 0 })
            Select  = @(@{ Column = @{ Expression = @{ SourceRef = @{ Source = "g" } }; Property = "pais" }; Name = "dim_geografia.pais" })
        }
    }
}
$visuals += @{ x = 210; y = 8; z = 21; width = 180; height = 48; config = $slicerPais }

# --- Text Box: Título ---
$titleBox = @{
    name         = "textbox_title"
    layouts      = @(@{ id = 0; position = @{ x = 0; y = 0; width = 0; height = 0 } })
    singleVisual = @{
        visualType = "textbox"
        objects    = @{
            general = @(@{
                    properties = @{
                        paragraphs = @(
                            @{
                                textRuns = @(
                                    @{
                                        value     = "VISAO ESTRATEGICA EXECUTIVA"
                                        textStyle = @{
                                            fontFamily = "Segoe UI Semibold"
                                            fontSize   = "16px"
                                            color      = "#FFFFFF"
                                        }
                                    }
                                )
                            }
                        )
                    }
                })
        }
    }
}
$visuals += @{ x = 420; y = 8; z = 22; width = 500; height = 48; config = $titleBox }

# Montar visualContainers
$visualContainers = @()
foreach ($v in $visuals) {
    $cfgCopy = $v.config
    $cfgCopy.layouts[0].position = @{ x = $v.x; y = $v.y; width = $v.width; height = $v.height }
    $cfgJson = $cfgCopy | ConvertTo-Json -Depth 15 -Compress
    $visualContainers += @{
        x = $v.x; y = $v.y; z = $v.z
        width = $v.width; height = $v.height
        config = $cfgJson
        filters = "[]"
        tabOrder = $v.z
    }
}

# Report config
$reportConfig = @{
    version                        = "5.50"
    themeCollection                = @{
        baseTheme = @{ name = "CY24SU06"; version = "5.50"; type = 2 }
    }
    activeSectionIndex             = 0
    defaultDrillFilterOtherVisuals = $true
} | ConvertTo-Json -Depth 5 -Compress

# Section config
$sectionConfig = @{
    name       = "ReportSection1"
    layouts    = @(@{ id = 0; position = @{ x = 0; y = 0; width = 1280; height = 720 } })
    visibility = 0
} | ConvertTo-Json -Depth 5 -Compress

# Full Layout JSON
$layout = @{
    id                 = 1
    resourcePackages   = @()
    sections           = @(
        @{
            name             = "ReportSection1"
            displayName      = "Visao Estrategica"
            filters          = "[]"
            ordinal          = 0
            visualContainers = $visualContainers
            config           = $sectionConfig
            displayOption    = 2
            width            = 1280
            height           = 720
        }
    )
    config             = $reportConfig
    layoutOptimization = 0
}

$layoutJson = $layout | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText("$reportDir\report.json", $layoutJson, [System.Text.Encoding]::UTF8)

Write-Host "  Layout criado com $($visuals.Count) visuais" -ForegroundColor Green

# --- 4. Abrir no Power BI Desktop ---
Write-Host "`n[4/4] Projeto PBIP criado!" -ForegroundColor Green
Write-Host ""
Write-Host "  Arquivo: $projectRoot\$projectName.pbip" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Visuais na pagina:" -ForegroundColor Yellow
Write-Host "    - 6 Cards KPI (Receita, Lucro, Margem, Unidades, CPV, Ticket)" -ForegroundColor Gray
Write-Host "    - Grafico de Linhas (Receita vs Lucro mensal)" -ForegroundColor Gray
Write-Host "    - Barras (Receita por Pais)" -ForegroundColor Gray
Write-Host "    - Donut (Segmentos)" -ForegroundColor Gray
Write-Host "    - Tabela (Ranking Produtos)" -ForegroundColor Gray
Write-Host "    - 2 Slicers (Ano, Pais)" -ForegroundColor Gray
Write-Host "    - Titulo" -ForegroundColor Gray
Write-Host ""
Write-Host "  Para abrir:" -ForegroundColor Yellow
Write-Host "    1. Feche o Power BI Desktop atual" -ForegroundColor Gray
Write-Host "    2. Abra: $projectRoot\$projectName.pbip" -ForegroundColor Gray
