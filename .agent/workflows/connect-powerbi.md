---
description: Como conectar ao Power BI Desktop via TOM (Tabular Object Model) para criar, modificar e consultar medidas DAX programaticamente.
---

# Conexão ao Power BI Desktop via TOM (Tabular Object Model)

## Visão Geral

O Power BI Desktop, ao abrir um relatório `.pbix`, inicia uma instância local do
**SQL Server Analysis Services (SSAS)** em modo tabular. Essa instância escuta em
uma porta TCP dinâmica, permitindo que ferramentas externas se conectem ao modelo
semântico e realizem operações como:

- Criar, modificar e excluir **medidas DAX**
- Consultar dados com **DAX queries**
- Inspecionar tabelas, colunas e relacionamentos
- Criar **tabelas calculadas**
- Modificar **format strings** e **display folders**

A conexão é feita via **TOM** (Tabular Object Model), uma API .NET da Microsoft
para manipulação programática de modelos tabulares do SSAS / Power BI.

---

## Pré-Requisitos

### 1. Power BI Desktop aberto

O Power BI Desktop **DEVE** estar aberto com um relatório `.pbix` carregado.
Sem um relatório aberto, a instância SSAS local não existe.

Arquivos `.pbix` conhecidos do projeto:

- `C:\Users\Claiton\Downloads\Financial_Fortress.pbix`
- `C:\Users\Claiton\Downloads\Financial_Fortress_Completo.pbix`
- `C:\Users\Claiton\Downloads\Financial_Fortress_Dashboard.pbix`

### 2. Módulo PowerShell `SqlServer`

O módulo **SqlServer** fornece as DLLs TOM necessárias para conexão.

// turbo

```powershell
# Verificar se está instalado
Get-Module -ListAvailable SqlServer
```

Se NÃO estiver instalado:

```powershell
Install-Module SqlServer -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
```

### 3. Provider MSOLAP registrado (opcional, mas recomendado)

O Power BI Desktop inclui o driver `msolap.dll` em seu diretório `bin`, mas
ele NÃO é registrado globalmente por padrão. Para registrá-lo:

```powershell
# Requer privilégios de administrador
Start-Process regsvr32 -ArgumentList '"C:\Program Files\Microsoft Power BI Desktop\bin\msolap.dll"' -Verb RunAs -Wait
```

---

## Passo a Passo da Conexão

### Passo 1: Localizar a Porta SSAS Local

A porta é armazenada em um arquivo dentro do diretório de workspaces do PBI.

> **ATENÇÃO**: O arquivo `msmdsrv.port.txt` é codificado em **UTF-16** (Unicode).
> Usar `Get-Content` diretamente insere bytes nulos (`\0`) na string, corrompendo
> a connection string. **SEMPRE** use `ReadAllText` com encoding Unicode.

// turbo

```powershell
$workspacesPath = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$workspace = Get-ChildItem -Path $workspacesPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $workspace) {
    Write-Host "ERRO: Power BI Desktop nao esta aberto ou nenhum relatorio carregado." -ForegroundColor Red
    exit 1
}

$portFile = Join-Path $workspace.FullName "Data\msmdsrv.port.txt"

# CRITICO: ler com encoding Unicode e remover bytes nulos residuais
$port = [System.IO.File]::ReadAllText($portFile, [System.Text.Encoding]::Unicode).Trim() -replace '\0',''

Write-Host "Porta SSAS local: $port"
```

**Caminho típico do arquivo de porta:**

```
C:\Users\<USER>\AppData\Local\Microsoft\Power BI Desktop\
  AnalysisServicesWorkspaces\
    AnalysisServicesWorkspace_<GUID>\
      Data\msmdsrv.port.txt
```

### Passo 2: Carregar as DLLs TOM

As DLLs necessárias estão dentro do módulo `SqlServer`. Devem ser carregadas
nesta ordem exata para evitar erros de dependência.

// turbo

```powershell
Import-Module SqlServer -ErrorAction Stop
$modulePath = (Get-Module SqlServer).ModuleBase

$dlls = @(
    "Microsoft.AnalysisServices.Core.dll",
    "Microsoft.AnalysisServices.dll",
    "Microsoft.AnalysisServices.Tabular.Json.dll",
    "Microsoft.AnalysisServices.Tabular.dll"
)

foreach ($dll in $dlls) {
    [System.Reflection.Assembly]::LoadFrom("$modulePath\$dll") | Out-Null
}

Write-Host "DLLs TOM carregadas com sucesso."
```

**Tipos .NET principais disponíveis após o carregamento:**

| Tipo                    | Namespace                            | Uso                       |
| ----------------------- | ------------------------------------ | ------------------------- |
| `Server`                | `Microsoft.AnalysisServices.Tabular` | Conexão ao SSAS           |
| `Database`              | `Microsoft.AnalysisServices.Tabular` | Acesso ao modelo          |
| `Model`                 | `Microsoft.AnalysisServices.Tabular` | Contém tabelas e relações |
| `Table`                 | `Microsoft.AnalysisServices.Tabular` | Tabela do modelo          |
| `Measure`               | `Microsoft.AnalysisServices.Tabular` | Medida DAX                |
| `CalculatedTableColumn` | `Microsoft.AnalysisServices.Tabular` | Coluna calculada          |
| `Partition`             | `Microsoft.AnalysisServices.Tabular` | Partição de dados         |

### Passo 3: Conectar ao Modelo

A connection string usa o formato `Data Source=localhost:<porta>`.

// turbo

```powershell
$server = New-Object Microsoft.AnalysisServices.Tabular.Server
$server.Connect("Data Source=localhost:$port")

$db    = $server.Databases[0]
$model = $db.Model

Write-Host "Conectado ao modelo: $($db.Name)"
Write-Host "Tabelas: $($model.Tables.Count)"
```

### Passo 4: Inspecionar o Modelo

// turbo

```powershell
# Listar todas as tabelas e suas medidas
foreach ($table in $model.Tables) {
    Write-Host "Tabela: $($table.Name) -- Colunas: $($table.Columns.Count) -- Medidas: $($table.Measures.Count)"
    foreach ($m in $table.Measures) {
        Write-Host "  Medida: $($m.Name) [$($m.DisplayFolder)]"
        Write-Host "    DAX: $($m.Expression)"
    }
}
```

### Passo 5: Criar Medidas DAX

```powershell
# Selecionar tabela onde a medida será criada
$targetTable = $model.Tables | Where-Object { $_.Name -eq "NomeDaTabela" }

# Criar nova medida
$measure = New-Object Microsoft.AnalysisServices.Tabular.Measure
$measure.Name          = "Nome da Medida"
$measure.Expression    = "SUM(tabela[coluna])"
$measure.Description   = "Descricao da medida"
$measure.DisplayFolder = "Pasta de Exibicao"
$measure.FormatString  = "$#,##0.00"

$targetTable.Measures.Add($measure)

# SALVAR as alterações no modelo
$model.SaveChanges()

Write-Host "Medida criada e modelo salvo!"
```

### Passo 6: Desconectar

```powershell
$server.Disconnect()
```

---

## Operações Avançadas

### Criar Tabela Calculada de Medidas

Se você quer uma tabela dedicada para organizar medidas (boa prática):

```powershell
$measureTable = New-Object Microsoft.AnalysisServices.Tabular.Table
$measureTable.Name = "Medidas"

# Partição calculada (necessária para a tabela existir)
$partition = New-Object Microsoft.AnalysisServices.Tabular.Partition
$partition.Name = "Medidas_part"
$src = New-Object Microsoft.AnalysisServices.Tabular.CalculatedPartitionSource
$src.Expression = 'ROW("Placeholder", 1)'
$partition.Source = $src
$measureTable.Partitions.Add($partition)

# Coluna placeholder (oculta)
$col = New-Object Microsoft.AnalysisServices.Tabular.CalculatedTableColumn
$col.Name         = "Placeholder"
$col.DataType     = [Microsoft.AnalysisServices.Tabular.DataType]::Int64
$col.IsHidden     = $true
$col.SourceColumn = "Placeholder"
$measureTable.Columns.Add($col)

$model.Tables.Add($measureTable)
$model.SaveChanges()
```

### Executar Query DAX

```powershell
# Via ADOMD (requer DLL separada ou OLE DB)
# Ou usando Invoke-ASCmd do módulo SqlServer:
$result = Invoke-ASCmd -Server "localhost:$port" -Query "EVALUATE SUMMARIZE(fato_financeiro, dim_produto[produto_nome], ""Total"", SUM(fato_financeiro[venda_liquida]))"
$result
```

### Atualizar Medida Existente

```powershell
$existingMeasure = $targetTable.Measures | Where-Object { $_.Name -eq "Total Sales" }
$existingMeasure.Expression = "CALCULATE(SUM(fato_financeiro[venda_liquida]), ISBLANK(fato_financeiro[desconto_sk]) = FALSE())"
$model.SaveChanges()
```

### Deletar Medida

```powershell
$measureToDelete = $targetTable.Measures | Where-Object { $_.Name -eq "Medida Antiga" }
if ($measureToDelete) {
    $targetTable.Measures.Remove($measureToDelete)
    $model.SaveChanges()
}
```

---

## Troubleshooting

### Erro: "Power BI Desktop não está aberto"

- Verifique se o Power BI Desktop está rodando **com um relatório aberto**
- Abra um `.pbix` e tente novamente

### Erro: "key-value set inválido" na connection string

- **Causa**: O arquivo `msmdsrv.port.txt` foi lido com encoding errado
- **Solução**: Use `[System.IO.File]::ReadAllText($path, [System.Text.Encoding]::Unicode)` e aplique `-replace '\0',''`
- **NÃO** use `Get-Content` simples para ler o arquivo de porta

### Erro: "tipo Server não encontrado"

- As DLLs TOM não foram carregadas na ordem correta
- Carregue **Core → AMO → Tabular.Json → Tabular** nessa sequência

### Erro: "SaveChanges falhou"

- Outra conexão pode estar bloqueando o modelo
- Feche o Tabular Editor ou outras ferramentas conectadas ao mesmo modelo
- Tente novamente

### Porta SSAS muda ao reabrir o PBI

- A porta é **dinâmica** e muda sempre que o Power BI Desktop reinicia
- O script deve **sempre** ler a porta do arquivo `msmdsrv.port.txt` antes de conectar

---

## Referência Rápida — Snippet Completo

```powershell
# === CONEXÃO RÁPIDA AO POWER BI DESKTOP ===

# 1. Porta
$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText("$($ws.FullName)\Data\msmdsrv.port.txt", [System.Text.Encoding]::Unicode).Trim() -replace '\0',''

# 2. DLLs
Import-Module SqlServer
$mp = (Get-Module SqlServer).ModuleBase
@("Microsoft.AnalysisServices.Core.dll","Microsoft.AnalysisServices.dll","Microsoft.AnalysisServices.Tabular.Json.dll","Microsoft.AnalysisServices.Tabular.dll") | % { [System.Reflection.Assembly]::LoadFrom("$mp\$_") | Out-Null }

# 3. Conectar
$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$model = $srv.Databases[0].Model

# 4. Operar...
# ...sua lógica aqui...

# 5. Salvar e desconectar
$model.SaveChanges()
$srv.Disconnect()
```

---

## Arquivos Relacionados do Projeto

| Arquivo                           | Descrição                                      |
| --------------------------------- | ---------------------------------------------- |
| `scripts/create_pbi_measures.ps1` | Script que cria 24 medidas DAX automaticamente |
| `tools/nuget.exe`                 | NuGet CLI para instalação de pacotes .NET      |
| `tools/packages/`                 | Pacotes NuGet AMO/TOM (fallback)               |
