# === FASE 1: GOVERNANCA E CAMADA SEMANTICA (TOM) ===

$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer -ErrorAction Stop
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.dll", "Microsoft.AnalysisServices.Tabular.Json.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$model = $srv.Databases[0].Model

Write-Host "Iniciando governanca na Ouro..." -ForegroundColor Cyan

# 1. Ocultar todas as chaves técnicas *_sk em TODAS as tabelas
$countHidden = 0
foreach ($t in $model.Tables) {
    foreach ($c in $t.Columns) {
        if ($c.Name -like "*_sk") {
            $c.IsHidden = $true
            $countHidden++
        }
    }
}
Write-Host "Ocultadas $countHidden colunas tecnicas (_sk)." -ForegroundColor Green

# 2. Renomear e Tipar colunas da Fato (Power Query M) 
$fato = $model.Tables | Where-Object { $_.Name -eq "fato_financeiro" }
if ($fato) {
    # Ajustando nomes lógicos na camada Semântica
    $fato.Columns["venda_liquida"].Name = "Receita Líquida"
    $fato.Columns["custo_bens_vendidos"].Name = "Custo (CPV)"
    $fato.Columns["lucro"].Name = "Lucro"
    $fato.Columns["unidades_vendidas"].Name = "Unidades Vendidas"
    
    # Ajustando M Partition para refletir a mesma coisa para o Engine
    $partFato = $fato.Partitions[0]
    $mFato = @'
let
    Fonte = Csv.Document(File.Contents("C:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\data\03_gold\fato_financeiro.csv"),[Delimiter=",", Columns=10, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    Cabecalhos = Table.PromoteHeaders(Fonte, [PromoteAllScalars=true]),
    Renomear = Table.RenameColumns(Cabecalhos,{{"unidades_vendidas", "Unidades Vendidas"}, {"venda_liquida", "Receita Líquida"}, {"custo_bens_vendidos", "Custo (CPV)"}, {"lucro", "Lucro"}}),
    Tipos = Table.TransformColumnTypes(Renomear,{{"fato_financeiro_sk", Int64.Type}, {"produto_sk", Int64.Type}, {"geografia_sk", Int64.Type}, {"segmento_sk", Int64.Type}, {"desconto_sk", type text}, {"tempo_sk", Int64.Type}, {"Unidades Vendidas", Int64.Type}, {"Receita Líquida", Currency.Type}, {"Custo (CPV)", Currency.Type}, {"Lucro", Currency.Type}})
in
    Tipos
'@
    $partFato.Source = New-Object Microsoft.AnalysisServices.Tabular.MPartitionSource
    $partFato.Source.Expression = $mFato
    Write-Host "Tabela fato_financeiro padronizada." -ForegroundColor Green
}

# 3. Traduzir Dim_Geografia
$dimGeo = $model.Tables | Where-Object { $_.Name -eq "dim_geografia" }
if ($dimGeo) {
    $dimGeo.Columns["pais"].Name = "País"
    
    $partGeo = $dimGeo.Partitions[0]
    $mGeo = @'
let
    Fonte = Csv.Document(File.Contents("C:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\data\03_gold\dim_geografia.csv"),[Delimiter=",", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Cabecalhos = Table.PromoteHeaders(Fonte, [PromoteAllScalars=true]),
    Renomear = Table.RenameColumns(Cabecalhos,{{"pais", "País"}}),
    Traduzir = Table.TransformColumns(Renomear, {{"País", each 
        if _ = "United States of America" then "Estados Unidos" else
        if _ = "France" then "França" else
        if _ = "Germany" then "Alemanha" else
        if _ = "Mexico" then "México" else
        if _ = "Canada" then "Canadá" else _, type text
    }})
in
    Traduzir
'@
    $partGeo.Source = New-Object Microsoft.AnalysisServices.Tabular.MPartitionSource
    $partGeo.Source.Expression = $mGeo
    Write-Host "Tabela dim_geografia traduzida." -ForegroundColor Green
}

# 4. Traduzir Dim_Segmento
$dimSeg = $model.Tables | Where-Object { $_.Name -eq "dim_segmento" }
if ($dimSeg) {
    $dimSeg.Columns["segmento_nome"].Name = "Segmento"
    
    $partSeg = $dimSeg.Partitions[0]
    $mSeg = @'
let
    Fonte = Csv.Document(File.Contents("C:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\data\03_gold\dim_segmento.csv"),[Delimiter=",", Columns=3, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    Cabecalhos = Table.PromoteHeaders(Fonte, [PromoteAllScalars=true]),
    Renomear = Table.RenameColumns(Cabecalhos,{{"segmento_nome", "Segmento"}}),
    Traduzir = Table.TransformColumns(Renomear, {{"Segmento", each 
        if _ = "Enterprise" then "Grande Empresa" else
        if _ = "Midmarket" then "Médio Porte" else
        if _ = "Small Business" then "Pequena Empresa" else
        if _ = "Government" then "Governo" else
        if _ = "Channel Partners" then "Parceiros" else _, type text
    }})
in
    Traduzir
'@
    $partSeg.Source = New-Object Microsoft.AnalysisServices.Tabular.MPartitionSource
    $partSeg.Source.Expression = $mSeg
    Write-Host "Tabela dim_segmento traduzida." -ForegroundColor Green
}

# 5. Gerar Dim_Tempo dinamicamente no M
$dimTempo = $model.Tables | Where-Object { $_.Name -eq "dim_tempo" }
if ($dimTempo) {
    $partTempo = $dimTempo.Partitions[0]
    $mTempo = @'
let
    DataMin = #date(2013, 1, 1),
    DataMax = #date(2014, 12, 31),
    Duracao = Duration.Days(DataMax - DataMin) + 1,
    ListaDatas = List.Dates(DataMin, Duracao, #duration(1,0,0,0)),
    TabelaDatas = Table.FromList(ListaDatas, Splitter.SplitByNothing(), {"data_completa"}, null, ExtraValues.Error),
    FormatarTipo = Table.TransformColumnTypes(TabelaDatas,{{"data_completa", type date}}),
    AddAno = Table.AddColumn(FormatarTipo, "ano", each Date.Year([data_completa]), Int64.Type),
    AddMes = Table.AddColumn(AddAno, "mes", each Date.Month([data_completa]), Int64.Type),
    AddDia = Table.AddColumn(AddMes, "dia", each Date.Day([data_completa]), Int64.Type),
    AddTrimestre = Table.AddColumn(AddDia, "trimestre", each Date.QuarterOfYear([data_completa]), Int64.Type),
    AddTempoSk = Table.AddColumn(AddTrimestre, "tempo_sk", each Date.Year([data_completa])*10000 + Date.Month([data_completa])*100 + Date.Day([data_completa]), Int64.Type)
in
    AddTempoSk
'@
    $partTempo.Source = New-Object Microsoft.AnalysisServices.Tabular.MPartitionSource
    $partTempo.Source.Expression = $mTempo
    Write-Host "Tabela dim_tempo atualizada com script gerador dinamico M." -ForegroundColor Green
}


$model.SaveChanges()
$srv.Disconnect()
Write-Host "Todas as atualizacoes semanticas (Fase 1) aplicadas no modelo com sucesso!" -ForegroundColor Green
