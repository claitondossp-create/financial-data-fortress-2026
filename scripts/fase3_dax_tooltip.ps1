# === CRIANDO MEDIDAS DE SMART TOOLTIP (FASE 3) ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$tbl = $srv.Databases[0].Model.Tables | Where-Object { $_.Name -eq "Medidas Insights" }

Write-Host "Injetando Medidas do Tooltip Acionavel..." -ForegroundColor Cyan

$measuresToAdd = @(
    @{
        Name          = "Tooltip Produto Campeao Receita"
        Expression    = @'
CALCULATE(
    MAX(dim_produto[produto]),
    TOPN(
        1,
        ALLSELECTED(dim_produto),
        [Receita Total],
        DESC
    )
)
'@
        DisplayFolder = "7. Storytelling (Textos)"
    },
    @{
        Name          = "Tooltip Insight Narrativo"
        Expression    = @'
VAR _Filtro = 
    IF(ISFILTERED(dim_geografia[País]), "Na região de " & SELECTEDVALUE(dim_geografia[País]) & ", ", 
        IF(ISFILTERED(dim_segmento[Segmento]), "No segmento " & SELECTEDVALUE(dim_segmento[Segmento]) & ", ", 
            "No cenário geral, "
        )
    )
VAR _ReceitaYoY = [Receita YoY %]
VAR _Evolucao = IF(_ReceitaYoY > 0, "cresceu ", IF(_ReceitaYoY < 0, "retraiu ", "manteve-se estável com "))
VAR _ProdTop = [Tooltip Produto Campeao Receita]

RETURN
    _Filtro & "a Receita Líquida " & _Evolucao & FORMAT(ABS(_ReceitaYoY), "0.0%") & " comparada ao período equivalente do ano passado. " &
    "Este resultado foi fortemente impactado pelas vendas do produto 🚀 " & _ProdTop & ", que liderou a geração de receita."
'@
        DisplayFolder = "7. Storytelling (Textos)"
    }
)

foreach ($def in $measuresToAdd) {
    if (-not ($tbl.Measures | Where-Object { $_.Name -eq $def.Name })) {
        $newM = New-Object Microsoft.AnalysisServices.Tabular.Measure
        $newM.Name = $def.Name
        $newM.Expression = $def.Expression
        $newM.DisplayFolder = $def.DisplayFolder
        $tbl.Measures.Add($newM)
        Write-Host "Medida $($def.Name) criada." -ForegroundColor Green
    }
    else {
        $m = $tbl.Measures | Where-Object { $_.Name -eq $def.Name }
        $m.Expression = $def.Expression
        Write-Host "Medida $($def.Name) atualizada." -ForegroundColor Yellow
    }
}

$srv.Databases[0].Model.SaveChanges()
$srv.Disconnect()
Write-Host "`nMedidas de Storytelling do Tooltip Inseridas com Sucesso!" -ForegroundColor Green
