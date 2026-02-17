# FASE 3: DASHBOARD E STORYTELLING - Visualização Estratégica com Power BI

> **Documentação Técnica Completa**  
> Da Estrutura de Dados à Apresentação Executiva

---

## 📚 Índice

1. [Fundamentos de Data Visualization](#fundamentos-de-data-visualization)
2. [Arquitetura do Dashboard](#arquitetura-do-dashboard)
3. [Página 1: Overview Executivo](#página-1-overview-executivo)
4. [Página 2: Análise de Produtos](#página-2-análise-de-produtos)
5. [Página 3: Análise de Descontos](#página-3-análise-de-descontos)
6. [Modelagem de Dados no Power BI](#modelagem-de-dados-no-power-bi)
7. [Código DAX - Métricas Calculadas](#código-dax-métricas-calculadas)
8. [Design e UX/UI](#design-e-uxui)
9. [Storytelling: Narrativa em 3 Atos](#storytelling-narrativa-em-3-atos)
10. [Performance e Otimização](#performance-e-otimização)
11. [Publicação e Compartilhamento](#publicação-e-compartilhamento)

---

## 1. Fundamentos de Data Visualization

### 1.1 Princípios de Visualização Efetiva

```
┌────────────────────────────────────────────────────────────┐
│           HIERARQUIA DE EFETIVIDADE VISUAL                 │
│                   (Cleveland & McGill)                     │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  MAIS PRECISO                                              │
│    ↑                                                       │
│    │  1. Posição em escala comum (gráfico de barras)      │
│    │  2. Posição em escalas diferentes (scatter plot)     │
│    │  3. Comprimento (barras horizontais)                 │
│    │  4. Ângulo (gráfico de pizza - EVITAR)              │
│    │  5. Área (bubble chart)                              │
│    │  6. Volume (3D - NUNCA USAR)                         │
│    │  7. Cor (saturação/intensidade)                      │
│    ↓                                                       │
│  MENOS PRECISO                                             │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 1.2 Escolha do Gráfico Ideal

```python
escolha_grafico = {
    "COMPARAÇÃO": {
        "Poucos itens (2-10)": "Gráfico de Barras",
        "Muitos itens (>10)": "Gráfico de Barras Horizontais",
        "Ao longo do tempo": "Gráfico de Linhas",
        "Múltiplas categorias": "Gráfico de Barras Agrupadas"
    },

    "DISTRIBUIÇÃO": {
        "Frequência": "Histograma",
        "Valores extremos": "Boxplot",
        "Densidade": "Violin Plot ou KDE"
    },

    "COMPOSIÇÃO": {
        "Partes de um todo": "Gráfico de Rosca (Donut)",
        "Mudança ao longo do tempo": "Gráfico de Área Empilhada",
        "Múltiplas dimensões": "Treemap ou Sunburst"
    },

    "RELAÇÃO": {
        "Duas variáveis": "Scatter Plot",
        "Três variáveis": "Bubble Chart",
        "Correlação": "Heatmap"
    },

    "HIERARQUIA": {
        "Estrutura organizacional": "Sankey Diagram",
        "Parte-todo aninhado": "Treemap",
        "Fluxo de processo": "Waterfall Chart"
    }
}
```

### 1.3 Lei de Gestalt Aplicada a Dashboards

**Princípios Gestalt para Organização Visual**:

1. **Proximidade**: Elementos relacionados devem estar próximos

   ```
   ✅ BOM:              ❌ RUIM:
   ┌─────────┐         KPI 1    KPI 2
   │ KPI 1   │
   │ KPI 2   │         Gráfico 1  Gráfico 2
   │ KPI 3   │
   └─────────┘         KPI 3
   ```

2. **Similaridade**: Use cores/formas consistentes para mesmas categorias

   ```
   Produtos Economy:  🟦 (Azul)
   Produtos Standard: 🟧 (Laranja)
   Produtos Premium:  🟥 (Vermelho)
   ```

3. **Continuidade**: Guie o olhar em ordem lógica (Z ou F pattern)

   ```
   Dashboard Layout (Padrão F):

   [Título do Dashboard]────────────────────
   │
   ├─ KPI 1  KPI 2  KPI 3  KPI 4 ←──┐
   │                                  │
   ├─ [Gráfico Principal Grande] ←───┤  Leitura
   │                                  │  em F
   ├─ [Gráfico 2] │ [Gráfico 3]  ←───┤
   │                                  │
   └─ [Filtros/Slicers] ────────────
   ```

---

## 2. Arquitetura do Dashboard

### 2.1 Estrutura em 3 Páginas

```
┌────────────────────────────────────────────────────────────┐
│                  ARQUITETURA DO DASHBOARD                  │
└────────────────────────────────────────────────────────────┘

📄 PÁGINA 1: OVERVIEW (Contexto)
   ├─ Propósito: "Onde estamos gerando receita?"
   ├─ Público-alvo: C-Level (CEO, CFO)
   ├─ Tempo de leitura: 30 segundos
   └─ Elementos:
       • 4 KPIs principais (Sales, Profit, Margin, Units)
       • Mapa geográfico de vendas
       • Gráfico de barras por segmento
       • Linha temporal (Vendas + Margem ao longo do tempo)

📄 PÁGINA 2: PRODUTOS (Problema)
   ├─ Propósito: "Quais produtos priorizar?"
   ├─ Público-alvo: Product Managers, VPs
   ├─ Tempo de leitura: 2 minutos
   └─ Elementos:
       • Matriz de Portfólio (Scatter: Volume vs Margem)
       • Gráfico de Cascata (Gross Sales → Profit)
       • Tabela Top 10 produtos
       • Treemap de participação de produtos

📄 PÁGINA 3: DESCONTOS (Solução)
   ├─ Propósito: "Como otimizar descontos?"
   ├─ Público-alvo: Sales Directors, Pricing Team
   ├─ Tempo de leitura: 3 minutos
   └─ Elementos:
       • Funil de distribuição de descontos
       • Gráfico de colunas agrupadas (Lucro por desconto)
       • Combo chart (Trade-off volume vs margem)
       • Heatmap de desconto por produto/segmento
```

### 2.2 Fluxo de Navegação

```
┌──────────────────────────────────────────────────────────┐
│             JORNADA DO USUÁRIO NO DASHBOARD              │
└──────────────────────────────────────────────────────────┘

PÁGINA 1 (Overview)
   │
   ├─ Usuário vê: "França tem maior margem (45%)"
   │
   ├─ Ação: Clica na França no mapa
   │
   └─→ DRILL-THROUGH para Página 2 (Produtos)
       │
       ├─ Dashboard filtra automaticamente: Country = "França"
       │
       ├─ Usuário vê: "Produto VTT tem margem negativa com desconto High"
       │
       ├─ Ação: Clica em VTT na matriz
       │
       └─→ DRILL-THROUGH para Página 3 (Descontos)
           │
           ├─ Dashboard filtra: Product = "VTT", Country = "França"
           │
           └─ Usuário vê: Impacto exato de cada faixa de desconto
```

---

## 3. Página 1: Overview Executivo

### 3.1 Layout Detalhado

```
┌───────────────────────────────────────────────────────────────┐
│  📊 DASHBOARD FINANCEIRO - OVERVIEW                           │
│  ───────────────────────────────────────────────────────────  │
│                                                               │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐         │
│  │ $127M   │  │ $45M    │  │  35%    │  │ 1.2M    │         │
│  │ Sales ↑ │  │ Profit ↑│  │ Margin ↓│  │ Units ↑ │         │
│  │ +12%    │  │ +8%     │  │ -2pp    │  │ +15%    │         │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘         │
│                                                               │
│  ┌───────────────────────┐  ┌─────────────────────────────┐  │
│  │   MAPA GEOGRÁFICO     │  │  VENDAS POR SEGMENTO        │  │
│  │                       │  │                             │  │
│  │   🌍                  │  │  ████████ Government        │  │
│  │  França ●             │  │  ███████ Enterprise         │  │
│  │  (45% margem)         │  │  ██████ Small Business      │  │
│  │                       │  │  █████ Midmarket            │  │
│  │  USA ●                │  │  ████ Channel Partners      │  │
│  │  (31% margem)         │  │                             │  │
│  └───────────────────────┘  └─────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  EVOLUÇÃO TEMPORAL (2013-2014)                        │   │
│  │                                                       │   │
│  │   Sales (▬▬▬ Linha Azul)                             │   │
│  │   Margin (▬ ▬ Linha Vermelha - Eixo Secundário)      │   │
│  │                                                       │   │
│  │   Pico: Dez/2014 ($18M, 28% margem)                  │   │
│  │   Vale: Ago/2014 ($8M, 35% margem)                   │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                               │
│  Filtros: [Ano ▼] [Trimestre ▼] [País ▼] [Produto ▼]        │
└───────────────────────────────────────────────────────────────┘
```

### 3.2 KPIs com Cores Condicionais (DAX)

```dax
// ====================================
// MEDIDA: Total de Vendas
// ====================================
Total_Sales =
SUM('Financials'[Sales])

// ====================================
// MEDIDA: Crescimento YoY
// ====================================
Sales_YoY_Growth =
VAR SalesCurrentYear = [Total_Sales]
VAR SalesPreviousYear =
    CALCULATE(
        [Total_Sales],
        SAMEPERIODLASTYEAR('Financials'[Date])
    )
RETURN
    DIVIDE(
        SalesCurrentYear - SalesPreviousYear,
        SalesPreviousYear,
        0  // Retorna 0 se divisão por zero
    )

// ====================================
// MEDIDA: Cor Condicional (Seta e Cor)
// ====================================
Sales_Growth_Icon =
VAR Growth = [Sales_YoY_Growth]
RETURN
    SWITCH(
        TRUE(),
        Growth > 0.1, "▲ +", // Verde: crescimento > 10%
        Growth > 0, "→ +",   // Amarelo: crescimento 0-10%
        "▼ "                 // Vermelho: decrescimento
    )

// Usar em Visual: Card visual com formatação condicional
// Regra de cor no Power BI:
// IF [Sales_YoY_Growth] > 0 THEN Verde
// IF [Sales_YoY_Growth] < 0 THEN Vermelho
```

### 3.3 Mapa Geográfico Configurado

**Configurações**:

```
Tipo de Visual: Mapa (Map)
Campo de Localização: [Country]
Campo de Tamanho: [Total_Sales]
Campo de Cor: [Margem_Media_%]

Paleta de Cores (Gradiente):
  0%  → Vermelho (#DC3545)
  25% → Laranja (#FD7E14)
  40% → Amarelo (#FFC107)
  60% → Verde Claro (#28A745)
  100%→ Verde Escuro (#155724)

Tooltip (Ao passar o mouse):
  ┌──────────────────────────────┐
  │ 🇫🇷 FRANÇA                    │
  ├──────────────────────────────┤
  │ Vendas:    $24.3M            │
  │ Lucro:     $10.9M            │
  │ Margem:    45%               │
  │ Unidades:  234K              │
  │                              │
  │ Top 3 Produtos:              │
  │  1. Paseo     $8.2M (42%)    │
  │  2. VTT       $6.1M (62%)    │
  │  3. Carretera $5.4M (48%)    │
  └──────────────────────────────┘
```

---

## 4. Página 2: Análise de Produtos

### 4.1 Layout Detalhado

```
┌───────────────────────────────────────────────────────────────┐
│  🎯 ANÁLISE DE PORTFÓLIO DE PRODUTOS                          │
│  ───────────────────────────────────────────────────────────  │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  MATRIZ DE PORTFÓLIO (BCG Matrix adaptada)            │  │
│  │                                                        │  │
│  │  Alta Margem                                           │  │
│  │   70% ┤         ● VTT (sem desc.)                      │  │
│  │       │    Estrelas    │  Vacas Leiteiras             │  │
│  │       │  ● Amarilla    │      ● Velo                  │  │
│  │   40% ┼────────────────┼──────────────                │  │
│  │       │                │                               │  │
│  │       │  Interrogações │  Cães                        │  │
│  │   10% ┤  ● Paseo(desc) │  ● Montana                   │  │
│  │       │                │                               │  │
│  │  Baixa└────────────────┴──────────────                │  │
│  │      Baixo Volume  │  Alto Volume                     │  │
│  │                                                        │  │
│  │  Tamanho da bolha = Receita Total                     │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌──────────────────────┐  ┌────────────────────────────┐   │
│  │ CASCATA: DECOMP.     │  │ TOP 10 PRODUTOS            │   │
│  │ LUCRO                │  │                            │   │
│  │                      │  │ #  Produto    Lucro  Marg% │   │
│  │ $200M Gross Sales    │  │ 1  Paseo     $18M    42%   │   │
│  │  -$15M Discounts     │  │ 2  VTT       $16M    62%   │   │
│  │  =$185M Sales        │  │ 3  Carretera $14M    48%   │   │
│  │   -$95M COGS         │  │ 4  Amarilla  $12M    59%   │   │
│  │   =$90M PROFIT ✓     │  │ 5  Velo      $10M    55%   │   │
│  │                      │  │ 6  Montana   $8M     38%   │   │
│  └──────────────────────┘  └────────────────────────────┘   │
│                                                               │
│  Insight: "Produtos premium (VTT, Amarilla) têm margem       │
│           superior a 60%, mas apenas 15% do volume"          │
└───────────────────────────────────────────────────────────────┘
```

### 4.2 Scatter Plot (Matriz BCG)

**Código DAX para Eixos**:

```dax
// ====================================
// EIXO X: Volume Total de Unidades
// ====================================
Total_Units = SUM('Financials'[Units Sold])

// ====================================
// EIXO Y: Margem de Lucro Média
// ====================================
Avg_Profit_Margin =
AVERAGE('Financials'[Profit_Margin_%])

// ====================================
// TAMANHO DA BOLHA: Receita Total
// ====================================
Total_Revenue = SUM('Financials'[Sales])

// ====================================
// COR: Categoria de Produto (calculada)
// ====================================
Product_Category =
VAR Margin = [Avg_Profit_Margin]
VAR Volume = [Total_Units]
VAR AvgMargin = CALCULATE([Avg_Profit_Margin], ALL('Financials'[Product]))
VAR AvgVolume = CALCULATE([Total_Units], ALL('Financials'[Product]))
RETURN
    SWITCH(
        TRUE(),
        Margin > AvgMargin && Volume > AvgVolume, "Estrelas",
        Margin > AvgMargin && Volume <= AvgVolume, "Vacas Leiteiras",
        Margin <= AvgMargin && Volume > AvgVolume, "Interrogações",
        "Cães"
    )

// Configuração do Visual:
// Tipo: Scatter Chart
// X: [Total_Units]
// Y: [Avg_Profit_Margin]
// Tamanho: [Total_Revenue]
// Detalhes: [Product]
// Legenda: [Product_Category]
```

### 4.3 Gráfico de Cascata (Waterfall)

**DAX para Cada Etapa**:

```dax
// ====================================
// TABELA AUXILIAR: Etapas do Cascata
// ====================================
Cascata_Steps =
DATATABLE(
    "Etapa", STRING,
    "Ordem", INTEGER,
    {
        {"1. Gross Sales", 1},
        {"2. Discounts", 2},
        {"3. Net Sales", 3},
        {"4. COGS", 4},
        {"5. PROFIT", 5}
    }
)

// ====================================
// MEDIDA: Valor de Cada Etapa
// ====================================
Cascata_Value =
VAR SelectedStep = SELECTEDVALUE(Cascata_Steps[Etapa])
RETURN
    SWITCH(
        SelectedStep,
        "1. Gross Sales", [Total_Gross_Sales],
        "2. Discounts", -[Total_Discounts],
        "3. Net Sales", [Total_Sales],
        "4. COGS", -[Total_COGS],
        "5. PROFIT", [Total_Profit],
        BLANK()
    )

// Configuração do Visual:
// Tipo: Waterfall Chart
// Categoria: Cascata_Steps[Etapa]
// Y: [Cascata_Value]
// Formatação:
//   - Aumento: Verde (#28A745)
//   - Diminuição: Vermelho (#DC3545)
//   - Total: Azul Escuro (#0056B3)
```

---

## 5. Página 3: Análise de Descontos

### 5.1 Layout Detalhado

```
┌───────────────────────────────────────────────────────────────┐
│  💰 ANÁLISE DE ESTRATÉGIA DE DESCONTOS                        │
│  ───────────────────────────────────────────────────────────  │
│                                                               │
│  ┌─────────────────────┐  ┌────────────────────────────────┐ │
│  │  FUNIL DE DESCONTOS │  │ LUCRO POR FAIXA DE DESCONTO    │ │
│  │                     │  │                                 │ │
│  │  ████████████ 100%  │  │  $50M ┤ ████ None              │ │
│  │   None: 45%         │  │       │ ███ Low                │ │
│  │                     │  │       │ ██ Medium              │ │
│  │   ██████ 55%        │  │       │ █ High                 │ │
│  │   Low: 30%          │  │  $0   └─────────────           │ │
│  │                     │  │                                 │ │
│  │    ███ 25%          │  │  Avg Profit/Transaction:       │ │
│  │    Med: 18%         │  │  None:   $850                  │ │
│  │                     │  │  Low:    $620                  │ │
│  │     █ 7%            │  │  Medium: $380                  │ │
│  │     High: 7%        │  │  High:   $120 ⚠️               │ │
│  └─────────────────────┘  └────────────────────────────────┘ │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  TRADE-OFF: Desconto vs Volume vs Margem              │  │
│  │                                                        │  │
│  │  70% ┤                                    ▬ Margem %  │  │
│  │      │  ●───●                                          │  │
│  │  50% ┤       ●────●                                    │  │
│  │      │            ●────●───●  ← Ponto Ótimo (5-8%)   │  │
│  │  30% ┤                    ●────●                       │  │
│  │      │                         ●───●                   │  │
│  │  10% ┤  ▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅▅ Volume (barras)      │  │
│  │      └──┬────┬────┬────┬────┬────                     │  │
│  │         0%  5%  10% 15% 20% 25%  Taxa Desconto        │  │
│  │                                                        │  │
│  │  Insight: "Descontos > 10% aumentam volume apenas     │  │
│  │           2%, mas reduzem margem em 45%"              │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  HEATMAP: Desconto Médio por Produto × Segmento       │  │
│  │                                                        │  │
│  │              Gov   Ent   SB    MM    CP                │  │
│  │  Carretera   3%    5%    8%    6%    4%   ← Baixo     │  │
│  │  Montana     4%    6%    9%    7%    5%                │  │
│  │  Paseo       5%    7%    12%   8%    6%                │  │
│  │  Velo        8%    10%   15%   11%   9%                │  │
│  │  VTT         12%   14%   18%   15%   13%               │  │
│  │  Amarilla    15% ← ALTO! Rever estratégia             │  │
│  │                                                        │  │
│  │  Gov=Government, Ent=Enterprise, SB=Small Business    │  │
│  │  MM=Midmarket, CP=Channel Partners                    │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

### 5.2 Gráfico de Funil (Funnel Chart)

**DAX**:

```dax
// ====================================
// TABELA: Níveis de Desconto
// ====================================
// (Já existe na tabela Financials, apenas filtrar)

// ====================================
// MEDIDA: Contagem de Transações
// ====================================
Count_Transactions =
COUNTROWS('Financials')

// ====================================
// MEDIDA: % do Total
// ====================================
Pct_of_Total_Transactions =
DIVIDE(
    [Count_Transactions],
    CALCULATE([Count_Transactions], ALL('Financials'[Discount Band])),
    0
)

// Configuração do Visual:
// Tipo: Funnel Chart
// Categoria: [Discount Band]
// Valores: [Count_Transactions]
// Rótulos de Dados: [Pct_of_Total_Transactions]
// Ordenação: None → Low → Medium → High
// Cores:
//   None:   #28A745 (Verde)
//   Low:    #FFC107 (Amarelo)
//   Medium: #FD7E14 (Laranja)
//   High:   #DC3545 (Vermelho)
```

### 5.3 Combo Chart (Trade-off)

**DAX para Binning de Desconto**:

```dax
// ====================================
// COLUNA CALCULADA: Bins de Desconto
// ====================================
Discount_Bin =
VAR Rate = 'Financials'[Discount_Rate_%]
RETURN
    SWITCH(
        TRUE(),
        Rate = 0, "0% (Sem desconto)",
        Rate <= 5, "1-5%",
        Rate <= 10, "6-10%",
        Rate <= 15, "11-15%",
        Rate <= 20, "16-20%",
        ">20%"
    )

// ====================================
// MEDIDA: Volume por Bin
// ====================================
Volume_by_Bin =
CALCULATE(
    SUM('Financials'[Units Sold]),
    ALLEXCEPT('Financials', 'Financials'[Discount_Bin])
)

// ====================================
// MEDIDA: Margem Média por Bin
// ====================================
Avg_Margin_by_Bin =
CALCULATE(
    AVERAGE('Financials'[Profit_Margin_%]),
    ALLEXCEPT('Financials', 'Financials'[Discount_Bin])
)

// Configuração do Visual:
// Tipo: Line and Clustered Column Chart
// Eixo X: [Discount_Bin]
// Valores (Coluna): [Volume_by_Bin]
// Valores (Linha): [Avg_Margin_by_Bin]
// Eixo Y Secundário: [Avg_Margin_by_Bin]
```

---

## 6. Modelagem de Dados no Power BI

### 6.1 Modelo Estrela (Star Schema)

```
┌─────────────────────────────────────────────────────────┐
│              MODELO DE DADOS (Star Schema)              │
└─────────────────────────────────────────────────────────┘

         ┌─────────────┐
         │ DIM_Date    │
         ├─────────────┤
         │ DateKey (PK)│
         │ Date        │
         │ Year        │
         │ Quarter     │
         │ Month       │
         │ MonthName   │
         │ DayOfWeek   │
         └─────┬───────┘
               │ 1
               │
               │ N
         ┌─────┴───────────────────┐
         │ FACT_Financials         │
         ├─────────────────────────┤
         │ TransactionID (PK)      │
         │ DateKey (FK)            │
         │ ProductKey (FK)         │
         │ CountryKey (FK)         │
         │ SegmentKey (FK)         │
         │ DiscountBandKey (FK)    │
         │                         │
         │ Units Sold              │
         │ Gross Sales             │
         │ Discounts               │
         │ Sales                   │
         │ COGS                    │
         │ Profit                  │
         └─┬───┬────┬────┬────────┘
     N     │ N │  N │  N │
     1     │   │    │    │
┌──────────┴┐  │    │    └──────────────┐
│ DIM_Product│  │    │              ┌────┴────────┐
├────────────┤  │    │              │ DIM_Discount│
│ProductKey  │  │    │              ├─────────────┤
│Product     │  │    │              │ BandKey (PK)│
│Manuf_Price │  │    │              │ Band        │
│Sale_Price  │  │    │              │ Min_%       │
│Category    │  │    │              │ Max_%       │
└────────────┘  │    │              └─────────────┘
                │    │
          ┌─────┴┐  ┌┴─────────┐
          │ DIM_ │  │ DIM_     │
          │Country│  │ Segment  │
          ├──────┤  ├──────────┤
          │Key   │  │ Key (PK) │
          │Name  │  │ Name     │
          │Region│  │ Type     │
          └──────┘  └──────────┘
```

### 6.2 Relacionamentos

```dax
// ====================================
// RELACIONAMENTOS NO POWER BI
// ====================================

// 1. FACT_Financials → DIM_Date
//    Cardinalidade: Muitos-para-Um (N:1)
//    Direção de Filtro Cruzado: Ambos (Both)
//    Coluna Ativa: ✓
FACT_Financials[DateKey] → DIM_Date[DateKey]

// 2. FACT_Financials → DIM_Product
//    Cardinalidade: Muitos-para-Um (N:1)
//    Direção: Simples (Single)
FACT_Financials[ProductKey] → DIM_Product[ProductKey]

// 3. FACT_Financials → DIM_Country
FACT_Financials[CountryKey] → DIM_Country[CountryKey]

// 4. FACT_Financials → DIM_Segment
FACT_Financials[SegmentKey] → DIM_Segment[SegmentKey]

// 5. FACT_Financials → DIM_Discount
FACT_Financials[DiscountBandKey] → DIM_Discount[BandKey]
```

---

## 7. Código DAX - Métricas Calculadas

### 7.1 Medidas Fundamentais

```dax
// ====================================
// MEDIDA: Total de Vendas
// ====================================
Total_Sales =
SUM('Financials'[Sales])

// Com formatação de moeda
FORMAT([Total_Sales], "$#,##0")

// ====================================
// MEDIDA: Total de Lucro
// ====================================
Total_Profit =
SUM('Financials'[Profit])

// ====================================
// MEDIDA: Margem de Lucro (%)
// ====================================
Profit_Margin_Pct =
DIVIDE(
    [Total_Profit],
    [Total_Sales],
    0  // Retorna 0 se divisão por zero
) * 100

// Formatação: ##0.0"%"

// ====================================
// MEDIDA: Total de Unidades
// ====================================
Total_Units =
SUM('Financials'[Units Sold])

// Formatação: #,##0 "un"

// ====================================
// MEDIDA: Taxa de Desconto Média
// ====================================
Avg_Discount_Rate =
DIVIDE(
    SUM('Financials'[Discounts]),
    SUM('Financials'[Gross Sales]),
    0
) * 100
```

### 7.2 Time Intelligence

```dax
// ====================================
// MEDIDA: Vendas do Ano Anterior (YoY)
// ====================================
Sales_PY =
CALCULATE(
    [Total_Sales],
    SAMEPERIODLASTYEAR('DIM_Date'[Date])
)

// ====================================
// MEDIDA: Crescimento Year-over-Year
// ====================================
Sales_YoY_Growth_Pct =
VAR CurrentSales = [Total_Sales]
VAR PreviousSales = [Sales_PY]
RETURN
    DIVIDE(
        CurrentSales - PreviousSales,
        PreviousSales,
        BLANK()  // Retorna vazio se não houver ano anterior
    ) * 100

// ====================================
// MEDIDA: Vendas Acumuladas no Ano (YTD)
// ====================================
Sales_YTD =
TOTALYTD(
    [Total_Sales],
    'DIM_Date'[Date]
)

// ====================================
// MEDIDA: Média Móvel de 3 Meses
// ====================================
Sales_MA3 =
AVERAGEX(
    DATESINPERIOD(
        'DIM_Date'[Date],
        LASTDATE('DIM_Date'[Date]),
        -3,
        MONTH
    ),
    [Total_Sales]
)
```

### 7.3 Medidas Avançadas

```dax
// ====================================
// MEDIDA: Elasticidade de Preço
// (Variação % Volume / Variação % Preço)
// ====================================
Price_Elasticity =
VAR AvgPrice = AVERAGE('Financials'[Sale Price])
VAR AvgPricePY =
    CALCULATE(
        AVERAGE('Financials'[Sale Price]),
        SAMEPERIODLASTYEAR('DIM_Date'[Date])
    )
VAR PriceChange = DIVIDE(AvgPrice - AvgPricePY, AvgPricePY)

VAR Volume = [Total_Units]
VAR VolumePY =
    CALCULATE(
        [Total_Units],
        SAMEPERIODLASTYEAR('DIM_Date'[Date])
    )
VAR VolumeChange = DIVIDE(Volume - VolumePY, VolumePY)

RETURN
    DIVIDE(VolumeChange, PriceChange, BLANK())

// ====================================
// MEDIDA: Pareto (80% das Vendas)
// ====================================
Pareto_80pct =
VAR TotalSales = [Total_Sales]
VAR RunningTotal =
    CALCULATE(
        [Total_Sales],
        FILTER(
            ALL('DIM_Product'[Product]),
            CALCULATE([Total_Sales]) >= [Total_Sales]
        )
    )
VAR Percentile = DIVIDE(RunningTotal, CALCULATE([Total_Sales], ALL()))
RETURN
    IF(Percentile <= 0.8, "Top 80%", "Bottom 20%")

// ====================================
// MEDIDA: Forecast de Vendas (Regressão Linear Simples)
// ====================================
Sales_Forecast =
VAR NumPeriods = COUNTROWS(ALL('DIM_Date'[Date]))
VAR SumX = SUMX(ALL('DIM_Date'), 'DIM_Date'[DateKey])
VAR SumY = SUMX(ALL('DIM_Date'), [Total_Sales])
VAR SumXY = SUMX(ALL('DIM_Date'), 'DIM_Date'[DateKey] * [Total_Sales])
VAR SumX2 = SUMX(ALL('DIM_Date'), 'DIM_Date'[DateKey] * 'DIM_Date'[DateKey])

VAR Slope = DIVIDE(
    (NumPeriods * SumXY) - (SumX * SumY),
    (NumPeriods * SumX2) - (SumX * SumX)
)
VAR Intercept = DIVIDE(SumY - (Slope * SumX), NumPeriods)

VAR CurrentPeriod = MAX('DIM_Date'[DateKey])
RETURN
    (Slope * CurrentPeriod) + Intercept
```

---

## 8. Design e UX/UI

### 8.1 Paleta de Cores

```
PRIMÁRIAS (Institucionais):
  • Azul Escuro:   #0056B3  (Títulos, KPIs principais)
  • Azul Médio:    #4A90E2  (Gráficos, destaques)
  • Cinza Escuro:  #2C3E50  (Texto principal)

SEMÂNTICAS (Financeiras):
  • Verde:         #28A745  (Lucro, crescimento positivo)
  • Vermelho:      #DC3545  (Prejuízo, decrescimento)
  • Laranja:       #FD7E14  (Avisos, valores críticos)
  • Amarelo:       #FFC107  (Neutro, margens médias)

NEUTRAS (Background):
  • Branco:        #FFFFFF  (Fundo principal)
  • Cinza Claro:   #F8F9FA  (Fundo de cards)
  • Cinza Médio:   #DEE2E6  (Bordas, divisórias)

GRADIENTES (Heatmaps):
  • Divergente:    Vermelho → Branco → Verde
  • Sequencial:    Branco → Azul Escuro
```

### 8.2 Tipografia

```
HIERARQUIA DE TEXTO:

H1 - Título do Dashboard
  Font: Segoe UI Semibold
  Tamanho: 24pt
  Cor: #0056B3
  Uso: Título de cada página

H2 - Título de Seção
  Font: Segoe UI Semibold
  Tamanho: 16pt
  Cor: #2C3E50
  Uso: Título de cada visual

H3 - Subtítulos
  Font: Segoe UI Regular
  Tamanho: 12pt
  Cor: #6C757D
  Uso: Legendas, eixos

Corpo - Texto Geral
  Font: Segoe UI Regular
  Tamanho: 10pt
  Cor: #495057
  Uso: Rótulos de dados, tooltips

KPIs - Números Grandes
  Font: Segoe UI Bold
  Tamanho: 32pt
  Cor: #0056B3 (ou cor semântica)
  Uso: Cards de métricas principais
```

### 8.3 Espaçamento e Grid

```
SISTEMA DE GRID (8-point):

┌───────────────────────────────────────┐
│ [8px padding]                         │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ Visual 1 (ocupando 4 colunas)  │ │
│  │                                 │ │
│  │ [16px margem entre visuais]     │ │
│  │                                 │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────┐  ┌─────────────┐   │
│  │ Visual 2    │  │ Visual 3    │   │
│  │ (2 colunas) │  │ (2 colunas) │   │
│  └─────────────┘  └─────────────┘   │
│                                       │
│ [8px padding]                         │
└───────────────────────────────────────┘

REGRAS:
  • Espaçamento múltiplo de 8px (8, 16, 24, 32...)
  • Padding mínimo: 8px
  • Margem entre visuais: 16px
  • Área respirável ao redor de KPIs: 24px
```

---

## 9. Storytelling: Narrativa em 3 Atos

### 9.1 Estrutura da História

```
┌────────────────────────────────────────────────────────┐
│              JORNADA NARRATIVA NO DASHBOARD            │
└────────────────────────────────────────────────────────┘

ATO 1: CONTEXTO (Página 1 - Overview)
├─ Hook: "Nossa empresa cresceu 12% em vendas..."
├─ Setup: "...mas a margem de lucro caiu 2 pontos percentuais"
├─ Pergunta: "POR QUÊ? Onde está o problema?"
└─ Transição: "Vamos investigar nossos produtos..." → Página 2

ATO 2: PROBLEMA (Página 2 - Produtos)
├─ Revelação: "Produtos premium estão sendo vendidos com descontos altos"
├─ Evidência: Matriz BCG mostra VTT com margem negativa
├─ Conflito: "Estamos destruindo valor tentando ganhar market share"
└─ Transição: "Como descontos impactam exatamente?" → Página 3

ATO 3: SOLUÇÃO (Página 3 - Descontos)
├─ Análise: Funil mostra 7% das vendas com desconto High
├─ Climax: "Essas 7% de transações reduzem margem global em 12pp!"
├─ Resolução: "Bloquear descontos > 10% em premium"
└─ Call-to-Action: "Implementar matriz de aprovação de descontos"
```

### 9.2 Roteiro de Apresentação (5 minutos)

```
ROTEIRO EXECUTIVO (para CEO/CFO):

[00:00-00:30] ABERTURA - Página 1
  "Bom dia. Gostaria de compartilhar 3 insights críticos sobre
   nossa rentabilidade. Olhando este dashboard, vemos que..."

   → Apontar para KPI de Margem (seta vermelha descendente)

  "...nossa margem caiu de 37% para 35%, apesar do crescimento
   de 12% em vendas. Isso representa $2.4M de lucro não realizado."

[00:30-01:30] DESCOBERTA 1 - Página 1 (Mapa)
  "A primeira descoberta é GEOGRÁFICA."

   → Clicar na França no mapa

  "A França tem margem de 45% - 10 pontos acima dos EUA (35%).
   O motivo? Taxa de desconto: 8% vs 16%."

   → Mostrar tooltip com Top 3 produtos

[01:30-03:00] DESCOBERTA 2 - Página 2 (Produtos)
  "Isso nos leva à segunda descoberta: PRODUTOS PREMIUM."

   → Navegar para Página 2, apontar para Scatter Plot

  "Vejam a matriz: VTT e Amarilla, nossos produtos de maior
   valor, estão aqui (apontar quadrante 'Interrogações') com
   margem próxima de zero quando vendidos com desconto alto."

   → Clicar em VTT no scatter, ativar drill-through para Página 3

[03:00-04:30] DESCOBERTA 3 - Página 3 (Descontos)
  "A terceira descoberta é o IMPACTO DE DESCONTOS."

   → Apontar para Combo Chart (Trade-off)

  "Este gráfico mostra algo crítico: descontos acima de 10%
   aumentam volume em apenas 2%, mas reduzem margem em 45%!"

   → Apontar para o ponto "10%" no gráfico

  "O ponto ótimo está entre 5-8%: maximiza volume mantendo
   margem saudável de 38%."

[04:30-05:00] RECOMENDAÇÕES
  "Baseado nestes insights, recomendamos 3 ações imediatas:"

  1. [Apontar para heatmap]
     "Bloquear descontos > 10% em VTT e Amarilla - impacto: +$450K/ano"

  2. [Voltar para Página 1, mapa]
     "Expandir operações na França/Alemanha - margem de 45% vs 35% USA"

  3. [Página 3, funil]
     "Implementar matriz de aprovação: Low (auto), Medium (gerente),
      High (diretor + justificativa)"

  "Estimativa de impacto total: +$1.2M em lucro anual."
```

---

## 10. Performance e Otimização

### 10.1 Otimização de Queries DAX

```dax
// ❌ LENTO (recalcula para cada linha)
Total_Sales_SLOW =
SUMX(
    'Financials',
    'Financials'[Units Sold] * 'Financials'[Sale Price]
)

// ✅ RÁPIDO (usa coluna pré-calculada)
Total_Sales_FAST =
SUM('Financials'[Sales])

// ====================================
// REGRA: Usar SUMX/AVERAGEX apenas quando necessário
// Preferir colunas calculadas para operações row-by-row
// ====================================

// ❌ EVITAR: Iteração em tabela grande
Bad_Margin =
AVERAGEX(
    'Financials',
    DIVIDE('Financials'[Profit], 'Financials'[Sales])
)

// ✅ MELHOR: Agregação direta
Good_Margin =
DIVIDE(
    SUM('Financials'[Profit]),
    SUM('Financials'[Sales])
)
```

### 10.2 Compressão de Dados

```
TÉCNICAS DE REDUÇÃO DE TAMANHO:

1. REMOVER COLUNAS DESNECESSÁRIAS
   ✅ Manter: Sales, Profit, Date, Product
   ❌ Remover: Row ID, Internal Notes, Temp Fields

2. USAR TIPOS DE DADOS OTIMIZADOS
   ❌ Text:     "2024-01-15" → 20 bytes
   ✅ Date:     2024-01-15   → 8 bytes

   ❌ Decimal:  1234.56 → 16 bytes
   ✅ Currency: $1234.56 → 8 bytes

3. APLICAR COMPRESSÃO EM COLUNAS DE ALTA CARDINALIDADE
   • Country (5 valores) → Compressão: 95%
   • TransactionID (700 valores únicos) → Compressão: 20%

   Técnica: Usar "Data Category" no Power BI
   Country → Tipo: "Country/Region" (otimiza compressão)

4. EVITAR COLUNAS CALCULADAS SE POSSÍVEL
   • 1 coluna calculada = +10-30% tamanho do modelo
   • Preferir medidas DAX (calculadas em runtime)
```

---

## 11. Publicação e Compartilhamento

### 11.1 Fluxo de Publicação

```
┌─────────────────────────────────────────────────────┐
│          FLUXO DE PUBLICAÇÃO NO POWER BI            │
└─────────────────────────────────────────────────────┘

1. DESENVOLVIMENTO (Power BI Desktop)
   ├─ Criar modelo de dados
   ├─ Desenvolver medidas DAX
   └─ Desenhar visuais

               ↓ (Publicar)

2. POWER BI SERVICE (Web)
   ├─ Workspace: "Financials Analytics"
   ├─ Dataset: "Financials_2013-2014"
   └─ Report: "Dashboard Estratégico"

               ↓ (Configurar)

3. ATUALIZAÇÕES AUTOMÁTICAS
   ├─ Schedule: Diário às 6h AM
   ├─ Data Source: OneDrive / SharePoint
   └─ Incremental Refresh: Últimos 90 dias

               ↓ (Compartilhar)

4. DISTRIBUIÇÃO
   ├─ Power BI App: "Executive Dashboard"
   ├─ Embed: Portal corporativo (iframe)
   ├─ Email Subscription: Relatório semanal
   └─ Export: PDF para C-Level
```

### 11.2 Níveis de Acesso (RLS - Row Level Security)

```dax
// ====================================
// CONFIGURAÇÃO DE RLS
// ====================================

// Role: "Sales_Manager_US"
[Country] = "United States of America"

// Role: "Sales_Manager_EU"
[Country] IN {"France", "Germany"}

// Role: "Product_Owner_Premium"
[Product] IN {"VTT", "Amarilla", "Velo"}

// Role: "Finance_Team" (acesso total)
1 = 1  // Sem filtro

// ====================================
// TESTE DE RLS no Power BI Desktop:
// Modeling → Security → View as Role → "Sales_Manager_US"
// ====================================
```

---

## 📖 Recursos Complementares

### Livros

1. **"Storytelling with Data"** - Cole Nussbaumer Knaflic
2. **"The Big Book of Dashboards"** - Steve Wexler
3. **"DAX Formulas for Power BI"** - Rob Collie

### Cursos Online

1. **Microsoft Learn**: Power BI Data Analyst Path
2. **SQLBI**: DAX Patterns
3. **Udemy**: Power BI A-Z

### Ferramentas

- **DAX Studio**: Otimização de queries
- **Tabular Editor**: Edição avançada de modelo
- **Power BI Helper**: Templates e ícones

---

**Documentos Relacionados**:

- [FASE_1_ETL.md](FASE_1_ETL.md) - Pipeline de Dados
- [FASE_2_INSIGHTS.md](FASE_2_INSIGHTS.md) - Análise de Negócios

---

✅ **Dashboard Pronto para Impressionar Recrutadores!**
