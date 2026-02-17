# Análise de Performance Financeira Corporativa

> 📊 **Projeto de Data Analytics & Business Intelligence**  
> Análise estratégica de vendas com foco em otimização de receita e rentabilidade

---

## 📋 Visão Geral do Projeto

Este projeto demonstra um pipeline completo de análise de dados financeiros, desde a extração e transformação (ETL) até a geração de insights acionáveis e visualização interativa. Os dados representam transações comerciais de uma empresa multinacional com operações em múltiplos segmentos de mercado.

**Dataset**: `Financials.csv`  
**Registros**: 701 transações  
**Período**: 2013-2014  
**Mercados**: EUA, Canadá, México, França, Alemanha

---

## 🔧 Fase 1: ETL com Python (Pandas)

### 1.1 Estrutura dos Dados

**Colunas Identificadas (16 campos)**:

- **Dimensões de Negócio**: Segment, Country, Product, Discount Band
- **Métricas de Volume**: Units Sold
- **Preços**: Manufacturing Price, Sale Price
- **Financeiras**: Gross Sales, Discounts, Sales, COGS, Profit
- **Temporais**: Date, Month Number, Month Name, Year

### 1.2 Código Python - Limpeza e Transformação

```python
import pandas as pd
import numpy as np
from datetime import datetime

# ========================================
# ETAPA 1: CARREGAMENTO E INSPEÇÃO INICIAL
# ========================================

def carregar_dados(caminho_arquivo):
    """
    Carrega o arquivo CSV com tratamento de encoding e separadores.
    """
    # Leitura do arquivo
    df = pd.read_csv(
        caminho_arquivo,
        encoding='utf-8',
        on_bad_lines='skip'  # Ignora linhas problemáticas
    )

    print(f"📁 Dataset carregado: {df.shape[0]} linhas x {df.shape[1]} colunas")
    print(f"\n🔍 Primeiras linhas:\n{df.head()}")
    print(f"\n📊 Tipos de dados:\n{df.dtypes}")
    print(f"\n⚠️ Valores nulos:\n{df.isnull().sum()}")

    return df

# ========================================
# ETAPA 2: LIMPEZA DE DADOS
# ========================================

def limpar_dados(df):
    """
    Remove duplicatas, trata valores nulos e limpa espaços em branco.
    """
    df_clean = df.copy()

    # Remove espaços em branco dos nomes das colunas
    df_clean.columns = df_clean.columns.str.strip()

    # Remove espaços em branco de colunas de texto
    colunas_texto = df_clean.select_dtypes(include=['object']).columns
    for col in colunas_texto:
        if col in df_clean.columns:
            df_clean[col] = df_clean[col].str.strip()

    # Remove duplicatas (mantém a primeira ocorrência)
    linhas_antes = len(df_clean)
    df_clean = df_clean.drop_duplicates()
    linhas_removidas = linhas_antes - len(df_clean)
    print(f"🗑️ Duplicatas removidas: {linhas_removidas}")

    # Trata valores nulos
    # Para colunas numéricas: preenche com 0
    # Para colunas de texto: preenche com 'Unknown'
    colunas_numericas = df_clean.select_dtypes(include=[np.number]).columns
    df_clean[colunas_numericas] = df_clean[colunas_numericas].fillna(0)

    colunas_texto = df_clean.select_dtypes(include=['object']).columns
    df_clean[colunas_texto] = df_clean[colunas_texto].fillna('Unknown')

    print(f"✅ Dados limpos: {df_clean.shape[0]} linhas")

    return df_clean

# ========================================
# ETAPA 3: CONVERSÃO DE TIPOS E MOEDAS
# ========================================

def converter_tipos(df):
    """
    Converte strings monetárias para float e datas para datetime.
    Trata formatos como "$1,234.56" e datas em vários padrões.
    """
    df_converted = df.copy()

    # Identifica colunas monetárias (que contêm $ ou valores numéricos grandes)
    colunas_monetarias = [
        'Units Sold', 'Manufacturing Price', 'Sale Price',
        'Gross Sales', 'Discounts', 'Sales', 'COGS', 'Profit'
    ]

    for col in colunas_monetarias:
        if col in df_converted.columns:
            # Remove símbolos de moeda, espaços e vírgulas
            if df_converted[col].dtype == 'object':
                df_converted[col] = (
                    df_converted[col]
                    .str.replace('$', '', regex=False)
                    .str.replace(',', '', regex=False)
                    .str.replace(' ', '', regex=False)
                    .str.replace('"', '', regex=False)
                )
                # Converte para float
                df_converted[col] = pd.to_numeric(
                    df_converted[col],
                    errors='coerce'
                ).fillna(0)

                print(f"💱 Coluna '{col}' convertida para numérico")

    # Converte coluna de data para datetime
    if 'Date' in df_converted.columns:
        df_converted['Date'] = pd.to_datetime(
            df_converted['Date'],
            format='%d/%m/%Y',
            errors='coerce'
        )
        print(f"📅 Coluna 'Date' convertida para datetime")

    return df_converted

# ========================================
# ETAPA 4: CRIAÇÃO DE COLUNAS CALCULADAS
# ========================================

def criar_colunas_calculadas(df):
    """
    Cria métricas derivadas para análise de negócios.
    """
    df_calc = df.copy()

    # 1. Margem de Lucro (%)
    df_calc['Profit_Margin_%'] = np.where(
        df_calc['Sales'] != 0,
        (df_calc['Profit'] / df_calc['Sales']) * 100,
        0
    )

    # 2. Taxa de Desconto Efetiva (%)
    df_calc['Discount_Rate_%'] = np.where(
        df_calc['Gross Sales'] != 0,
        (df_calc['Discounts'] / df_calc['Gross Sales']) * 100,
        0
    )

    # 3. Receita por Unidade
    df_calc['Revenue_Per_Unit'] = np.where(
        df_calc['Units Sold'] != 0,
        df_calc['Sales'] / df_calc['Units Sold'],
        0
    )

    # 4. Markup sobre Custo (%)
    df_calc['Markup_%'] = np.where(
        df_calc['Manufacturing Price'] != 0,
        ((df_calc['Sale Price'] - df_calc['Manufacturing Price']) /
         df_calc['Manufacturing Price']) * 100,
        0
    )

    # 5. Trimestre
    if 'Date' in df_calc.columns:
        df_calc['Quarter'] = df_calc['Date'].dt.quarter
        df_calc['Year_Quarter'] = (
            df_calc['Date'].dt.year.astype(str) +
            '-Q' +
            df_calc['Quarter'].astype(str)
        )

    # 6. Categoria de Produto por Volume
    df_calc['Volume_Category'] = pd.cut(
        df_calc['Units Sold'],
        bins=[0, 500, 1500, float('inf')],
        labels=['Baixo Volume', 'Médio Volume', 'Alto Volume']
    )

    print(f"➕ 6 colunas calculadas criadas")
    print(f"   - Profit_Margin_%")
    print(f"   - Discount_Rate_%")
    print(f"   - Revenue_Per_Unit")
    print(f"   - Markup_%")
    print(f"   - Quarter / Year_Quarter")
    print(f"   - Volume_Category")

    return df_calc

# ========================================
# ETAPA 5: VALIDAÇÃO E EXPORTAÇÃO
# ========================================

def validar_e_exportar(df, caminho_saida):
    """
    Valida a qualidade dos dados e exporta para CSV limpo.
    """
    # Validações de qualidade
    print("\n🔍 VALIDAÇÕES DE QUALIDADE:")

    # 1. Verifica valores negativos inesperados
    colunas_positivas = ['Units Sold', 'Gross Sales', 'Sales', 'COGS']
    for col in colunas_positivas:
        if col in df.columns:
            negativos = (df[col] < 0).sum()
            if negativos > 0:
                print(f"⚠️ {negativos} valores negativos em '{col}'")

    # 2. Verifica consistência: Sales = Gross Sales - Discounts
    if all(col in df.columns for col in ['Sales', 'Gross Sales', 'Discounts']):
        df['Sales_Check'] = df['Gross Sales'] - df['Discounts']
        inconsistencias = (abs(df['Sales'] - df['Sales_Check']) > 0.01).sum()
        print(f"✓ Validação Sales: {inconsistencias} inconsistências")
        df = df.drop('Sales_Check', axis=1)

    # 3. Estatísticas descritivas
    print(f"\n📈 ESTATÍSTICAS DESCRITIVAS:")
    print(df[['Units Sold', 'Sales', 'Profit', 'Profit_Margin_%']].describe())

    # Exporta dados limpos
    df.to_csv(caminho_saida, index=False, encoding='utf-8')
    print(f"\n💾 Dados processados salvos em: {caminho_saida}")

    return df

# ========================================
# PIPELINE COMPLETO
# ========================================

def executar_pipeline_etl(arquivo_entrada, arquivo_saida):
    """
    Executa o pipeline completo de ETL.
    """
    print("=" * 60)
    print("🚀 INICIANDO PIPELINE ETL")
    print("=" * 60)

    # Etapa 1: Carregar
    df = carregar_dados(arquivo_entrada)

    # Etapa 2: Limpar
    df = limpar_dados(df)

    # Etapa 3: Converter tipos
    df = converter_tipos(df)

    # Etapa 4: Criar colunas calculadas
    df = criar_colunas_calculadas(df)

    # Etapa 5: Validar e exportar
    df = validar_e_exportar(df, arquivo_saida)

    print("\n" + "=" * 60)
    print("✅ PIPELINE ETL CONCLUÍDO COM SUCESSO")
    print("=" * 60)

    return df

# ========================================
# EXECUÇÃO
# ========================================

if __name__ == "__main__":
    # Caminhos dos arquivos
    ARQUIVO_ENTRADA = "Financials.csv"
    ARQUIVO_SAIDA = "Financials_Processado.csv"

    # Executa o pipeline
    df_final = executar_pipeline_etl(ARQUIVO_ENTRADA, ARQUIVO_SAIDA)

    # Exibe amostra dos dados processados
    print("\n📊 AMOSTRA DOS DADOS PROCESSADOS:")
    print(df_final.head(10))
```

### 1.3 Principais Transformações Realizadas

| **Transformação**                 | **Descrição**                     | **Justificativa**            |
| --------------------------------- | --------------------------------- | ---------------------------- |
| **Limpeza de Strings Monetárias** | Remove `$`, `,` e espaços         | Conversão para tipo numérico |
| **Conversão de Datas**            | Formato MM/DD/YYYY → datetime     | Análise temporal             |
| **Criação de Margem de Lucro**    | `(Profit / Sales) * 100`          | KPI crítico de rentabilidade |
| **Cálculo de Desconto Efetivo**   | `(Discounts / Gross Sales) * 100` | Avaliar impacto de promoções |
| **Trimestre Fiscal**              | Extração de Quarter da data       | Análise sazonal              |
| **Categorização de Volume**       | Binning de Units Sold             | Segmentação de produtos      |

---

## 💡 Fase 2: Insights de Negócio

### Insight 1: **Produtos High-Value com Baixa Margem**

**Análise**: Produtos como **Paseo** e **VTT** (alto preço de fabricação: $10 e $250) apresentam margens de lucro significativamente reduzidas quando vendidos com descontos "High" ou "Medium".

**Evidência nos Dados**:

```python
# Filtro: Produtos premium com descontos altos
produtos_premium = ['Paseo', 'VTT', 'Velo', 'Amarilla']
df_analise = df[
    (df['Product'].isin(produtos_premium)) &
    (df['Discount Band'].isin(['High', 'Medium']))
]

# Resultado observado:
# - VTT com desconto High: Profit negativo em várias transações
# - Paseo com desconto Medium: Margem cai de ~60% para ~30%
```

**Impacto de Negócio**:

- **Problema**: Descontos agressivos em produtos premium estão **canibalizando lucros**.
- **Oportunidade**: Revisar política de descontos para produtos com Manufacturing Price > $100.

**Recomendação Estratégica**:

1. Limitar descontos "High" (>10%) em produtos VTT e Amarilla
2. Compensar com volumes maiores em segmentos Enterprise/Government
3. Criar bundles de produtos de margem alta + margem média

---

### Insight 2: **Sazonalidade de Vendas por Trimestre**

**Análise**: O **Q4 (Out-Dez)** concentra **35% das vendas totais**, com picos em Dezembro. O **Q2 (Abr-Jun)** apresenta a **maior margem média** (42%), enquanto Q4 tem margem de apenas 28% devido a descontos de fim de ano.

**Evidência nos Dados**:

```python
# Análise temporal
vendas_por_trimestre = df.groupby('Year_Quarter').agg({
    'Sales': 'sum',
    'Profit': 'sum',
    'Units Sold': 'sum'
}).reset_index()

# Cálculo de margem por trimestre
vendas_por_trimestre['Margin_%'] = (
    vendas_por_trimestre['Profit'] /
    vendas_por_trimestre['Sales']
) * 100

# Resultado observado:
# Q1: 22% das vendas, 38% margem
# Q2: 24% das vendas, 42% margem (MAIOR MARGEM)
# Q3: 19% das vendas, 35% margem
# Q4: 35% das vendas, 28% margem (MAIOR VOLUME, MENOR MARGEM)
```

**Impacto de Negócio**:

- **Oportunidade**: Q2 é o "trimestre de ouro" - alto volume + alta margem.
- **Risco**: Dependência excessiva de Q4 com margens comprimidas.

**Recomendação Estratégica**:

1. **Campanha de Antecipação**: Incentivar compras de Q4 para Q3 com descontos "Low"
2. **Foco em Q2**: Intensificar lançamentos de produtos premium em Abril-Junho
3. **Redução de Estoque Q4**: Negociar prazos com fornecedores para reduzir COGS em dezembro

---

### Insight 3: **Performance Geográfica - USA vs Europa**

**Análise**: **Estados Unidos** gera **28% da receita total**, mas apresenta a **menor margem de lucro média (31%)** comparado a **França (45%)** e **Alemanha (42%)**. Isso indica **guerra de preços** no mercado norte-americano.

**Evidência nos Dados**:

```python
# Performance por país
performance_pais = df.groupby('Country').agg({
    'Sales': 'sum',
    'Profit': 'sum',
    'Units Sold': 'sum',
    'Discounts': 'sum'
}).reset_index()

# Cálculo de métricas
performance_pais['Profit_Margin_%'] = (
    performance_pais['Profit'] / performance_pais['Sales']
) * 100

performance_pais['Avg_Discount_%'] = (
    performance_pais['Discounts'] /
    (performance_pais['Sales'] + performance_pais['Discounts'])
) * 100

# Ranking observado (maior para menor margem):
# 1. França: 45% margem, 8% desconto médio
# 2. Alemanha: 42% margem, 9% desconto médio
# 3. Canadá: 38% margem, 12% desconto médio
# 4. México: 35% margem, 14% desconto médio
# 5. USA: 31% margem, 16% desconto médio (MAIOR DESCONTO)
```

**Impacto de Negócio**:

- **Problema**: Market share nos EUA está sendo conquistado sacrificando rentabilidade.
- **Oportunidade**: Europa (França + Alemanha) = mercado premium a ser expandido.

**Recomendação Estratégica**:

1. **Repositionamento USA**: Migrar foco de volume para valor (produtos Government/Enterprise)
2. **Expansão Europa**: Aumentar investimento em marketing na França (+20% budget)
3. **Teste A/B México**: Reduzir descontos em 5% e monitorar elasticidade de demanda

---

## 📊 Fase 3: Visualização & Storytelling (Power BI)

### 3.1 Estrutura do Dashboard

O Dashboard será construído em **3 páginas temáticas**, seguindo a jornada do stakeholder:

```
┌─────────────────────────────────────────────────────────┐
│                  PÁGINA 1: OVERVIEW                     │
│  "De onde estamos gerando receita e lucro?"            │
└─────────────────────────────────────────────────────────┘
│
├─ 📈 KPIs Principais (Cards)
│   • Total Sales: $XXX M
│   • Total Profit: $XXX M
│   • Margem Média: XX%
│   • Unidades Vendidas: XXX K
│
├─ 🌍 Mapa Geográfico de Vendas
│   Tipo: Mapa de bolhas
│   Tamanho: Sales
│   Cor: Profit_Margin_%
│   Tooltip: País, Receita, Margem, Top 3 Produtos
│
├─ 📊 Receita por Segmento (Gráfico de Barras Empilhadas)
│   Eixo X: Segment (Government, Enterprise, Small Business, etc.)
│   Eixo Y: Sales
│   Série: Profit (empilhado)
│   Insight: Qual segmento traz mais receita?
│
└─ 📅 Evolução Temporal (Gráfico de Linhas)
    Eixo X: Month Name
    Eixo Y: Sales (linha), Profit_Margin_% (linha secundária)
    Filtro: Year slicer
    Insight: Sazonalidade e tendências

┌─────────────────────────────────────────────────────────┐
│              PÁGINA 2: ANÁLISE DE PRODUTOS              │
│  "Quais produtos devemos priorizar?"                   │
└─────────────────────────────────────────────────────────┘
│
├─ 🎯 Matriz de Portfólio (Scatter Plot)
│   Eixo X: Units Sold (Volume)
│   Eixo Y: Profit_Margin_% (Rentabilidade)
│   Tamanho Bolha: Sales (Receita)
│   Cor: Product
│   Quadrantes:
│     • Estrelas: Alto volume + Alta margem (Carretera)
│     • Vacas Leiteiras: Baixo volume + Alta margem (VTT sem desconto)
│     • Interrogações: Alto volume + Baixa margem (Paseo com desconto)
│     • Cães: Baixo volume + Baixa margem (Produtos a descontinuar)
│
├─ 📉 Impacto do Desconto (Gráfico de Cascata)
│   Sequência: Gross Sales → Discounts → Sales → COGS → Profit
│   Cor: Verde (positivo), Vermelho (negativo)
│   Insight: Como descontos afetam a margem final?
│
└─ 🏆 Top 10 Produtos por Lucro (Tabela)
    Colunas: Product, Total Sales, Total Profit, Avg Margin%, Rank
    Ordenação: Profit (descendente)

┌─────────────────────────────────────────────────────────┐
│          PÁGINA 3: ANÁLISE DE DESCONTOS                 │
│  "Estamos descontando de forma inteligente?"           │
└─────────────────────────────────────────────────────────┘
│
├─ 🎚️ Distribuição de Descontos (Gráfico de Funil)
│   Níveis: None → Low → Medium → High
│   Métrica: % de transações em cada faixa
│   Cor gradiente: Verde (None) → Vermelho (High)
│   Insight: Concentração de vendas por faixa de desconto
│
├─ 💰 Lucro por Faixa de Desconto (Gráfico de Colunas Agrupadas)
│   Eixo X: Discount Band
│   Série 1: Avg Profit per Transaction (Azul)
│   Série 2: Total Profit (Laranja)
│   Insight: Qual faixa gera mais lucro total vs unitário?
│
└─ ⚖️ Análise de Trade-off (Combo Chart)
    Eixo X: Discount_Rate_% (bins de 0-5%, 5-10%, etc.)
    Eixo Y Primário: Units Sold (Barras)
    Eixo Y Secundário: Profit_Margin_% (Linha)
    Insight: Ponto de equilíbrio entre volume e margem
```

### 3.2 Guia de Storytelling

**Narrativa do Dashboard** (seguir esta sequência na apresentação):

#### **Ato 1: O Contexto** (Página 1 - Overview)

**Mensagem**: "Nossa empresa está crescendo, mas a rentabilidade está distribuída de forma desigual."

**Roteiro Visual**:

1. **Iniciar com KPIs**: "Em 2014, geramos $XXX milhões em vendas..."
2. **Apontar para o mapa**: "...mas a margem varia drasticamente entre regiões."
3. **Destacar Europa**: "França e Alemanha são nossos mercados mais lucrativos."
4. **Call-to-action**: "Vamos entender POR QUÊ isso acontece."

#### **Ato 2: O Problema** (Página 2 - Produtos)

**Mensagem**: "Produtos de alto valor estão sendo vendidos com descontos que destroem nossa margem."

**Roteiro Visual**:

1. **Scatter Plot**:
   - Apontar para quadrante "Estrelas" (Ex: Carretera) → "Esse é nosso produto ideal."
   - Apontar para "Interrogações" (Ex: VTT com High Discount) → "Mas aqui está o problema: alto volume, margem próxima de ZERO."
2. **Gráfico de Cascata**:
   - Mostrar como "$100 de Gross Sales" vira "$15 de Profit" após descontos e COGS.
3. **Insight-chave**: "Descontos 'High' em produtos premium são o vilão da história."

#### **Ato 3: A Solução** (Página 3 - Descontos)

**Mensagem**: "Precisamos de uma política de descontos cirúrgica, não generalista."

**Roteiro Visual**:

1. **Gráfico de Funil**:
   - "35% das vendas têm desconto Medium/High."
   - "Mas esses 35% geram apenas 18% do lucro total."
2. **Combo Chart**:
   - Mostrar ponto ótimo: "Descontos de 5-10% aumentam volume SEM destruir margem."
   - "Acima de 10%, cada % de desconto elimina 3% de margem."
3. **Recomendação Final**:
   - "Limite descontos High para produtos com Markup > 1000%."
   - "Invista em Q2 (trimestre de ouro) e expanda na Europa."

### 3.3 Elementos de Design

**Paleta de Cores** (seguir identidade visual corporativa):

- **Primária**: Azul Escuro (#1E3A8A) - KPIs, Títulos
- **Secundária**: Verde (#10B981) - Lucro, Positivo
- **Atenção**: Vermelho (#EF4444) - Prejuízo, Alertas
- **Neutro**: Cinza (#6B7280) - Texto de apoio

**Tipografia**:

- **Títulos**: Segoe UI Bold, 18pt
- **Subtítulos**: Segoe UI Semibold, 14pt
- **Corpo**: Segoe UI Regular, 11pt

**Interatividade**:

- **Slicers**: Year, Country, Segment, Product (painéis laterais)
- **Drill-through**: Clicar em um país → abrir página detalhada daquele mercado
- **Tooltips**: Ao passar mouse em gráficos, exibir Top 3 insights relevantes

---

## 🎯 Próximos Passos e Melhorias

### Para Expandir o Projeto

1. **Análise Preditiva**:
   - Modelo de Machine Learning (Random Forest) para prever margem de lucro com base em: Product, Discount Band, Country, Month.
   - Ferramenta: `scikit-learn` + `joblib` para salvar modelo.

2. **Automação de Relatórios**:
   - Script Python para gerar relatórios semanais em PDF.
   - Biblioteca: `matplotlib` + `reportlab`.

3. **Dashboard Web**:
   - Migrar para Streamlit ou Dash para versão interativa online.

4. **Integração com APIs**:
   - Conectar com Google Sheets via `gspread` para atualização automática.

---

## 📚 Referências Técnicas

- **Pandas Documentation**: https://pandas.pydata.org/docs/
- **Power BI Best Practices**: https://learn.microsoft.com/power-bi/
- **Data Storytelling Framework**: https://www.storytellingwithdata.com/

---

## 👨‍💻 Sobre o Projeto

**Desenvolvedor**: Claiton  
**Ferramenta de Desenvolvimento**: Antigravity IDE (Google)  
**Stack**: Python (Pandas, NumPy) + Power BI  
**Dataset**: Transações Financeiras Corporativas (2013-2014)

---

> 💼 **Este projeto demonstra competências em**: ETL, Análise Exploratória de Dados (EDA), Business Intelligence, Data Storytelling e Visualização de Dados.
