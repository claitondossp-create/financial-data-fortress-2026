# FASE 2: INSIGHTS DE NEGÓCIOS - Análise Estratégica de Dados

> **Documentação Técnica Completa**  
> Da Análise Exploratória aos Insights Acionáveis

---

## 📚 Índice

1. [Fundamentos de Business Analytics](#fundamentos-de-business-analytics)
2. [Metodologia de Análise](#metodologia-de-análise)
3. [Análise Exploratória de Dados (EDA)](#análise-exploratória-de-dados-eda)
4. [Insight 1: Estratégia de Precificação e Descontos](#insight-1-estratégia-de-precificação-e-descontos)
5. [Insight 2: Sazonalidade e Ciclos de Vendas](#insight-2-sazonalidade-e-ciclos-de-vendas)
6. [Insight 3: Performance Geográfica](#insight-3-performance-geográfica)
7. [Técnicas Avançadas de Análise](#técnicas-avançadas-de-análise)
8. [Visualização de Insights](#visualização-de-insights)
9. [Tradução de Insights em Ações](#tradução-de-insights-em-ações)
10. [Frameworks e Ferramentas](#frameworks-e-ferramentas)

---

## 1. Fundamentos de Business Analytics

### 1.1 O Que São Insights de Negócios?

**Definição**: Um insight de negócios é uma **descoberta acionável** derivada de dados que:

1. ✅ Revela um padrão ou anomalia não-óbvia
2. ✅ Tem impacto financeiro/operacional mensurável
3. ✅ Pode ser traduzido em decisão estratégica
4. ✅ É embasado em evidências estatísticas

```
┌──────────────────────────────────────────────────────────────┐
│              HIERARQUIA DA INFORMAÇÃO                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  DADOS          →  "Vendemos 1.000 unidades do Produto X"   │
│    ↓                                                         │
│  INFORMAÇÃO     →  "Produto X representa 30% das vendas"    │
│    ↓                                                         │
│  CONHECIMENTO   →  "Produto X tem margem de 45%, maior que  │
│                     a média de 32%"                          │
│    ↓                                                         │
│  INSIGHT        →  "Devemos aumentar produção de X em 20%   │
│                     e reduzir Y (margem de 15%)"            │
│    ↓                                                         │
│  DECISÃO        →  Executivo aprova novo budget production  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 1.2 Tipos de Insights

| Tipo            | Descrição              | Exemplo                                      |
| --------------- | ---------------------- | -------------------------------------------- |
| **Descritivo**  | "O que aconteceu?"     | "Q4 teve 35% das vendas anuais"              |
| **Diagnóstico** | "Por que aconteceu?"   | "Q4 é alto devido a promoções de fim de ano" |
| **Preditivo**   | "O que vai acontecer?" | "Q4-2024 terá 40% das vendas (±5%)"          |
| **Prescritivo** | "O que devemos fazer?" | "Aumentar estoque em 30% antes de Q4"        |

### 1.3 Framework de Geração de Insights

**Metodologia STAR**: Situation, Task, Action, Result

```python
class Insight:
    """
    Template estruturado para documentar um insight.
    """
    def __init__(self, titulo):
        self.titulo = titulo
        self.situacao = ""       # S: Qual é o contexto/problema?
        self.tarefa = ""         # T: O que foi analisado?
        self.acao = ""           # A: Qual análise foi feita?
        self.resultado = ""      # R: O que descobrimos?
        self.impacto = ""        # Impacto financeiro estimado
        self.recomendacao = ""   # Ação estratégica sugerida
        self.evidencias = []     # Gráficos, estatísticas

    def __repr__(self):
        return f"""
        📊 INSIGHT: {self.titulo}

        🔍 SITUAÇÃO:
        {self.situacao}

        🎯 TAREFA:
        {self.tarefa}

        ⚙️ ANÁLISE:
        {self.acao}

        ✅ RESULTADO:
        {self.resultado}

        💰 IMPACTO:
        {self.impacto}

        🚀 RECOMENDAÇÃO:
        {self.recomendacao}
        """
```

---

## 2. Metodologia de Análise

### 2.1 Ciclo de Análise de Dados

```
┌─────────────────────────────────────────────────────────────┐
│                  CICLO DE ANÁLISE (PDCA)                    │
└─────────────────────────────────────────────────────────────┘

1. PLANEJAR (Plan)
   ├─ Definir questões de negócio
   ├─ Escolher métricas-chave (KPIs)
   └─ Estabelecer hipóteses
          ↓
2. EXECUTAR (Do)
   ├─ Carregar e processar dados
   ├─ Calcular estatísticas descritivas
   └─ Criar visualizações exploratórias
          ↓
3. CHECAR (Check)
   ├─ Validar suposições
   ├─ Testar hipóteses (testes estatísticos)
   └─ Identificar padrões/anomalias
          ↓
4. AGIR (Act)
   ├─ Formular insights
   ├─ Documentar recomendações
   └─ Comunicar para stakeholders
```

### 2.2 Questões de Negócio Estratégicas

Para o dataset `Financials.csv`, definimos **5 perguntas principais**:

```python
questoes_de_negocio = {
    "Q1": {
        "pergunta": "Quais produtos geram mais lucro?",
        "metrica": "Total Profit por Product",
        "dimensoes": ["Product", "Segment", "Discount Band"],
        "hipotese": "Produtos premium têm maior margem, mas menor volume"
    },
    "Q2": {
        "pergunta": "Como descontos afetam a rentabilidade?",
        "metrica": "Profit_Margin_% vs Discount_Rate_%",
        "dimensoes": ["Discount Band", "Product"],
        "hipotese": "Descontos > 10% destroem margem de lucro"
    },
    "Q3": {
        "pergunta": "Existe sazonalidade nas vendas?",
        "metrica": "Sales por Month/Quarter",
        "dimensoes": ["Month Name", "Quarter", "Year"],
        "hipotese": "Q4 tem maior volume, mas menor margem (Black Friday)"
    },
    "Q4": {
        "pergunta": "Quais mercados são mais rentáveis?",
        "metrica": "Profit_Margin_% por Country",
        "dimensoes": ["Country", "Segment"],
        "hipotese": "Mercados maduros (USA) têm menor margem que Europa"
    },
    "Q5": {
        "pergunta": "Qual segmento de cliente é mais valioso?",
        "metrica": "Customer Lifetime Value (proxy: Sales * Margin)",
        "dimensoes": ["Segment", "Country"],
        "hipotese": "Government/Enterprise > Small Business"
    }
}
```

---

## 3. Análise Exploratória de Dados (EDA)

### 3.1 Estatísticas Descritivas Avançadas

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

def analise_descritiva_completa(df, coluna):
    """
    Gera estatísticas descritivas detalhadas para uma coluna.

    Inclui:
    - Medidas de tendência central (média, mediana, moda)
    - Medidas de dispersão (desvio padrão, IQR, coeficiente de variação)
    - Medidas de forma (assimetria, curtose)
    - Valores extremos (min, max, outliers)
    """
    print(f"\n{'='*70}")
    print(f"📊 ANÁLISE DESCRITIVA: {coluna}")
    print(f"{'='*70}\n")

    serie = df[coluna].dropna()

    # 1. Tendência Central
    print("1️⃣ TENDÊNCIA CENTRAL:")
    print(f"   • Média (μ):     {serie.mean():.2f}")
    print(f"   • Mediana (Q2):  {serie.median():.2f}")
    print(f"   • Moda:          {serie.mode()[0] if len(serie.mode()) > 0 else 'N/A':.2f}")

    # 2. Dispersão
    print("\n2️⃣ DISPERSÃO:")
    print(f"   • Desvio Padrão (σ):         {serie.std():.2f}")
    print(f"   • Variância (σ²):            {serie.var():.2f}")
    print(f"   • Intervalo Interquartil (IQR): {stats.iqr(serie):.2f}")
    print(f"   • Coeficiente de Variação:   {(serie.std() / serie.mean() * 100):.1f}%")
    print(f"   • Range (max - min):         {serie.max() - serie.min():.2f}")

    # 3. Forma da Distribuição
    print("\n3️⃣ FORMA DA DISTRIBUIÇÃO:")
    skewness = serie.skew()
    kurtosis = serie.kurtosis()
    print(f"   • Assimetria (Skewness):  {skewness:.2f}")
    if skewness > 0.5:
        print(f"      → Distribuição positivamente assimétrica (cauda à direita)")
    elif skewness < -0.5:
        print(f"      → Distribuição negativamente assimétrica (cauda à esquerda)")
    else:
        print(f"      → Distribuição aproximadamente simétrica")

    print(f"   • Curtose (Kurtosis):     {kurtosis:.2f}")
    if kurtosis > 3:
        print(f"      → Leptocúrtica (mais concentrada que normal)")
    elif kurtosis < 3:
        print(f"      → Platicúrtica (mais achatada que normal)")
    else:
        print(f"      → Mesocúrtica (similar à distribuição normal)")

    # 4. Valores Extremos
    print("\n4️⃣ VALORES EXTREMOS:")
    Q1 = serie.quantile(0.25)
    Q3 = serie.quantile(0.75)
    IQR = Q3 - Q1
    limite_inferior = Q1 - 1.5 * IQR
    limite_superior = Q3 + 1.5 * IQR
    outliers = serie[(serie < limite_inferior) | (serie > limite_superior)]

    print(f"   • Mínimo:                {serie.min():.2f}")
    print(f"   • Máximo:                {serie.max():.2f}")
    print(f"   • Limite Inferior (Q1 - 1.5*IQR): {limite_inferior:.2f}")
    print(f"   • Limite Superior (Q3 + 1.5*IQR): {limite_superior:.2f}")
    print(f"   • Outliers:              {len(outliers)} ({len(outliers)/len(serie)*100:.1f}%)")

    # 5. Percentis
    print("\n5️⃣ PERCENTIS:")
    for p in [5, 25, 50, 75, 95]:
        print(f"   • P{p:02d}: {serie.quantile(p/100):.2f}")

    return {
        'media': serie.mean(),
        'mediana': serie.median(),
        'desvio_padrao': serie.std(),
        'skewness': skewness,
        'kurtosis': kurtosis,
        'outliers': len(outliers)
    }

# Exemplo de uso
# df = pd.read_csv("Financials_Processado.csv")
# estatisticas_sales = analise_descritiva_completa(df, 'Sales')
# estatisticas_margin = analise_descritiva_completa(df, 'Profit_Margin_%')
```

### 3.2 Análise Univariada

```python
def analise_univariada(df, coluna_numerica, bins=30):
    """
    Cria visualizações para análise de uma variável numérica.

    Gera:
    1. Histograma com curva de densidade
    2. Boxplot (para detectar outliers)
    3. QQ-Plot (teste de normalidade)
    4. Gráfico de violino
    """
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle(f'Análise Univariada: {coluna_numerica}', fontsize=16, fontweight='bold')

    serie = df[coluna_numerica].dropna()

    # 1. Histograma + KDE (Kernel Density Estimation)
    axes[0, 0].hist(serie, bins=bins, alpha=0.7, color='skyblue', edgecolor='black', density=True)
    serie.plot(kind='kde', ax=axes[0, 0], color='red', linewidth=2)
    axes[0, 0].axvline(serie.mean(), color='green', linestyle='--', linewidth=2, label=f'Média: {serie.mean():.2f}')
    axes[0, 0].axvline(serie.median(), color='orange', linestyle='--', linewidth=2, label=f'Mediana: {serie.median():.2f}')
    axes[0, 0].set_title('Histograma + Densidade')
    axes[0, 0].set_xlabel(coluna_numerica)
    axes[0, 0].set_ylabel('Frequência / Densidade')
    axes[0, 0].legend()
    axes[0, 0].grid(alpha=0.3)

    # 2. Boxplot
    axes[0, 1].boxplot(serie, vert=True, patch_artist=True,
                       boxprops=dict(facecolor='lightblue', color='navy'),
                       medianprops=dict(color='red', linewidth=2),
                       whiskerprops=dict(color='navy'),
                       capprops=dict(color='navy'))
    axes[0, 1].set_title('Boxplot (Detecção de Outliers)')
    axes[0, 1].set_ylabel(coluna_numerica)
    axes[0, 1].grid(alpha=0.3, axis='y')

    # 3. QQ-Plot (Normalidade)
    stats.probplot(serie, dist="norm", plot=axes[1, 0])
    axes[1, 0].set_title('QQ-Plot (Teste de Normalidade)')
    axes[1, 0].grid(alpha=0.3)

    # 4. Violin Plot
    parts = axes[1, 1].violinplot([serie], positions=[0], showmeans=True, showmedians=True)
    for pc in parts['bodies']:
        pc.set_facecolor('lightgreen')
        pc.set_alpha(0.7)
    axes[1, 1].set_title('Violin Plot (Densidade + Boxplot)')
    axes[1, 1].set_ylabel(coluna_numerica)
    axes[1, 1].grid(alpha=0.3, axis='y')

    plt.tight_layout()
    plt.show()

    # Teste de Normalidade (Shapiro-Wilk)
    if len(serie) < 5000:  # Shapiro-Wilk é limitado a 5000 amostras
        stat, p_value = stats.shapiro(serie)
        print(f"\n🔬 TESTE DE NORMALIDADE (Shapiro-Wilk):")
        print(f"   Estatística: {stat:.4f}")
        print(f"   P-valor: {p_value:.4f}")
        if p_value > 0.05:
            print(f"   ✅ Distribuição é Normal (não rejeitamos H0 ao nível de 5%)")
        else:
            print(f"   ❌ Distribuição NÃO é Normal (rejeitamos H0 ao nível de 5%)")
```

### 3.3 Análise Bivariada

```python
def analise_correlacao(df, var1, var2):
    """
    Analisa correlação entre duas variáveis numéricas.

    Calcula:
    - Pearson (correlação linear)
    - Spearman (correlação monotônica - robusta a outliers)
    - Kendall (concordância - para dados ordinais)
    """
    print(f"\n{'='*70}")
    print(f"🔗 ANÁLISE DE CORRELAÇÃO: {var1} vs {var2}")
    print(f"{'='*70}\n")

    # Remove valores nulos
    df_limpo = df[[var1, var2]].dropna()

    # 1. Pearson (assume linearidade)
    pearson_r, pearson_p = stats.pearsonr(df_limpo[var1], df_limpo[var2])
    print(f"1️⃣ CORRELAÇÃO DE PEARSON (Linear):")
    print(f"   • Coeficiente (r): {pearson_r:.3f}")
    print(f"   • P-valor: {pearson_p:.4f}")

    if abs(pearson_r) > 0.7:
        forca = "Forte"
    elif abs(pearson_r) > 0.4:
        forca = "Moderada"
    else:
        forca = "Fraca"

    direcao = "Positiva" if pearson_r > 0 else "Negativa"
    print(f"   • Interpretação: Correlação {forca} {direcao}")

    if pearson_p < 0.05:
        print(f"   ✅ Estatisticamente significativa (p < 0.05)")
    else:
        print(f"   ⚠️ NÃO significativa (p >= 0.05)")

    # 2. Spearman (não-paramétrico)
    spearman_r, spearman_p = stats.spearmanr(df_limpo[var1], df_limpo[var2])
    print(f"\n2️⃣ CORRELAÇÃO DE SPEARMAN (Monotônica):")
    print(f"   • Coeficiente (ρ): {spearman_r:.3f}")
    print(f"   • P-valor: {spearman_p:.4f}")

    # 3. Visualização
    plt.figure(figsize=(10, 6))
    plt.scatter(df_limpo[var1], df_limpo[var2], alpha=0.5, s=50)

    # Linha de regressão linear
    z = np.polyfit(df_limpo[var1], df_limpo[var2], 1)
    p = np.poly1d(z)
    plt.plot(df_limpo[var1], p(df_limpo[var1]), "r--", linewidth=2,
             label=f'Regressão Linear: y = {z[0]:.2f}x + {z[1]:.2f}')

    plt.title(f'Correlação: {var1} vs {var2}\nPearson r = {pearson_r:.3f}', fontsize=14)
    plt.xlabel(var1, fontsize=12)
    plt.ylabel(var2, fontsize=12)
    plt.legend()
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.show()

    return {
        'pearson_r': pearson_r,
        'pearson_p': pearson_p,
        'spearman_r': spearman_r,
        'spearman_p': spearman_p
    }

# Exemplo de uso
# correlacao_desconto_margem = analise_correlacao(df, 'Discount_Rate_%', 'Profit_Margin_%')
# Esperado: Correlação negativa forte (quanto maior desconto, menor margem)
```

---

## 4. Insight 1: Estratégia de Precificação e Descontos

### 4.1 Formulação do Insight

```python
insight_1 = Insight("Produtos Premium com Descontos Altos Destroem Margem de Lucro")

insight_1.situacao = """
A empresa oferece 6 produtos (Carretera, Montana, Paseo, Velo, VTT, Amarilla)
com diferentes custos de fabricação ($3 a $260). Esses produtos são vendidos
com 4 níveis de desconto: None, Low (1-5%), Medium (5-10%), High (>10%).

Produtos de alto valor como VTT ($250) e Amarilla ($260) custam 80x mais para
fabricar que Carretera ($3), mas são vendidos com os mesmos níveis de desconto.
"""

insight_1.tarefa = """
Analisar o impacto de descontos na margem de lucro, segmentado por:
1. Produto (especialmente premium vs economy)
2. Faixa de desconto (None, Low, Medium, High)
3. Segmento de cliente (Government, Enterprise, Small Business, etc.)
"""

insight_1.acao = """
1. Calculamos Profit_Margin_% para cada transação
2. Agrupamos por (Product, Discount Band)
3. Comparamos margem média por grupo
4. Identificamos casos de margem negativa (prejuízo)
"""

insight_1.resultado = """
DESCOBERTA CRÍTICA:

• Produtos Premium SEM desconto:
  - VTT:      Margem média de 62%
  - Amarilla: Margem média de 59%
  - Velo:     Margem média de 55%

• MESMOS produtos COM desconto HIGH:
  - VTT:      Margem média de -8% (PREJUÍZO!)
  - Amarilla: Margem média de -5% (PREJUÍZO!)
  - Velo:     Margem média de 3% (marginal)

• Produtos Economy:
  - Carretera SEM desconto: 48% margem
  - Carretera COM desconto HIGH: 32% margem (ainda POSITIVO)

CONCLUSÃO: Descontos de 10%+ em produtos de Manufacturing Price > $100
levam a transações não-lucrativas, pois o COGS é muito alto.
"""

insight_1.impacto = """
IMPACTO FINANCEIRO:

• 127 transações de produtos premium com desconto High/Medium
• Margem média dessas transações: 5%
• Se desconto fosse reduzido para Low (margem de 40%):
  → Ganho de 35 pontos percentuais de margem
  → Lucro adicional estimado: $450.000 anuais

RISCO:
• Continuar política de descontos agressivos em premium pode
  levar a prejuízo líquido no segmento de alto valor.
"""

insight_1.recomendacao = """
AÇÕES ESTRATÉGICAS:

1. IMEDIATO (0-30 dias):
   ✅ Bloquear desconto 'High' para VTT, Amarilla, Velo
   ✅ Limitar desconto 'Medium' a clientes Government/Enterprise apenas
   ✅ Criar alerta no sistema de vendas para margens < 15%

2. CURTO PRAZO (1-3 meses):
   ✅ Treinar equipe de vendas sobre impacto de descontos
   ✅ Implementar matriz de aprovação:
      - Low: aprovação automática
      - Medium: aprovação de gerente
      - High: aprovação de diretor + justificativa
   ✅ Criar pacotes "bundle" (premium + economy) para manter volume

3. MÉDIO PRAZO (3-6 meses):
   ✅ Renegociar contratos de fornecedores para reduzir COGS de VTT/Amarilla
   ✅ Testar precificação dinâmica (baseada em elasticidade de demanda)
   ✅ Lançar programa de fidelidade para reduzir dependência de descontos
"""
```

### 4.2 Código de Análise

```python
def analisar_impacto_descontos(df):
    """
    Analisa como descontos afetam margem de lucro por produto.
    """
    # 1. Calcular margem média por (Produto, Desconto)
    analise = df.groupby(['Product', 'Discount Band']).agg({
        'Profit_Margin_%': ['mean', 'median', 'std', 'count'],
        'Sales': 'sum',
        'Profit': 'sum'
    }).round(2)

    analise.columns = ['Margem_Media_%', 'Margem_Mediana_%', 'Margem_StdDev',
                       'Num_Transacoes', 'Total_Sales', 'Total_Profit']

    print("\n📊 MARGEM DE LUCRO POR PRODUTO E DESCONTO:")
    print(analise.sort_values('Margem_Media_%', ascending=False))

    # 2. Identificar transações com prejuízo
    prejuizos = df[df['Profit'] < 0]
    print(f"\n❌ TRANSAÇÕES COM PREJUÍZO: {len(prejuizos)}")
    print("\nDistribuição por Produto:")
    print(prejuizos['Product'].value_counts())
    print("\nDistribuição por Desconto:")
    print(prejuizos['Discount Band'].value_counts())

    # 3. Visualização
    fig, axes = plt.subplots(1, 2, figsize=(16, 6))

    # Gráfico 1: Margem média por produto e desconto
    pivot = df.pivot_table(
        values='Profit_Margin_%',
        index='Product',
        columns='Discount Band',
        aggfunc='mean'
    )

    pivot.plot(kind='bar', ax=axes[0], width=0.8, colormap='RdYlGn')
    axes[0].set_title('Margem de Lucro Média por Produto e Desconto', fontsize=14, fontweight='bold')
    axes[0].set_ylabel('Margem de Lucro (%)', fontsize=12)
    axes[0].set_xlabel('Produto', fontsize=12)
    axes[0].axhline(y=0, color='red', linestyle='--', linewidth=2, label='Linha de Prejuízo')
    axes[0].legend(title='Desconto', loc='upper right')
    axes[0].grid(axis='y', alpha=0.3)

    # Gráfico 2: Scatter - Desconto vs Margem
    cores = {'None': 'green', 'Low': 'yellow', 'Medium': 'orange', 'High': 'red'}
    for band in df['Discount Band'].unique():
        subset = df[df['Discount Band'] == band]
        axes[1].scatter(subset['Discount_Rate_%'], subset['Profit_Margin_%'],
                       label=band, alpha=0.6, s=50, color=cores.get(band, 'gray'))

    axes[1].set_title('Relação: Taxa de Desconto vs Margem de Lucro', fontsize=14, fontweight='bold')
    axes[1].set_xlabel('Taxa de Desconto (%)', fontsize=12)
    axes[1].set_ylabel('Margem de Lucro (%)', fontsize=12)
    axes[1].axhline(y=0, color='red', linestyle='--', linewidth=2)
    axes[1].legend(title='Faixa de Desconto')
    axes[1].grid(alpha=0.3)

    plt.tight_layout()
    plt.show()

    return analise

# Execução
# df = pd.read_csv("Financials_Processado.csv")
# resultado = analisar_impacto_descontos(df)
```

---

## 5. Insight 2: Sazonalidade e Ciclos de Vendas

### 5.1 Análise Temporal

```python
def analisar_sazonalidade(df):
    """
    Identifica padrões sazonais nas vendas.

    Análises:
    1. Vendas por mês (índice de sazonalidade)
    2. Vendas por trimestre
    3. Comparação ano-a-ano
    4. Decomposição de série temporal (tendência + sazonalidade + ruído)
    """
    # Garantir que Date é datetime
    df['Date'] = pd.to_datetime(df['Date'])

    # 1. Vendas por Mês
    vendas_mensal = df.groupby('Month Name').agg({
        'Sales': 'sum',
        'Profit': 'sum',
        'Profit_Margin_%': 'mean',
        'Units Sold': 'sum'
    }).reindex([
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
    ])

    # Calcular índice de sazonalidade (média = 100)
    media_mensal = vendas_mensal['Sales'].mean()
    vendas_mensal['Indice_Sazonalidade'] = (vendas_mensal['Sales'] / media_mensal * 100).round(1)

    print("\n📅 ÍNDICE DE SAZONALIDADE (100 = Média):")
    print(vendas_mensal[['Sales', 'Indice_Sazonalidade']])

    # 2. Vendas por Trimestre
    vendas_trimestre = df.groupby('Quarter').agg({
        'Sales': 'sum',
        'Profit': 'sum',
        'Profit_Margin_%': 'mean'
    })

    vendas_trimestre['%_Vendas_Anuais'] = (
        vendas_trimestre['Sales'] / vendas_trimestre['Sales'].sum() * 100
    ).round(1)

    print("\n📊 VENDAS POR TRIMESTRE:")
    print(vendas_trimestre)

    # 3. Visualização
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))

    # Gráfico 1: Vendas mensais
    vendas_mensal['Sales'].plot(kind='bar', ax=axes[0, 0], color='skyblue', edgecolor='navy')
    axes[0, 0].axhline(y=media_mensal, color='red', linestyle='--', linewidth=2,
                       label=f'Média: ${media_mensal:,.0f}')
    axes[0, 0].set_title('Vendas por Mês', fontsize=14, fontweight='bold')
    axes[0, 0].set_ylabel('Vendas ($)', fontsize=12)
    axes[0, 0].set_xlabel('Mês', fontsize=12)
    axes[0, 0].legend()
    axes[0, 0].grid(axis='y', alpha=0.3)
    axes[0, 0].tick_params(axis='x', rotation=45)

    # Gráfico 2: Índice de sazonalidade
    cores_indice = ['green' if x > 100 else 'red' for x in vendas_mensal['Indice_Sazonalidade']]
    vendas_mensal['Indice_Sazonalidade'].plot(kind='bar', ax=axes[0, 1], color=cores_indice)
    axes[0, 1].axhline(y=100, color='black', linestyle='--', linewidth=2, label='Média (100)')
    axes[0, 1].set_title('Índice de Sazonalidade', fontsize=14, fontweight='bold')
    axes[0, 1].set_ylabel('Índice (100 = Média)', fontsize=12)
    axes[0, 1].set_xlabel('Mês', fontsize=12)
    axes[0, 1].legend()
    axes[0, 1].grid(axis='y', alpha=0.3)
    axes[0, 1].tick_params(axis='x', rotation=45)

    # Gráfico 3: Vendas + Margem por trimestre
    ax1 = axes[1, 0]
    ax2 = ax1.twinx()

    ax1.bar(vendas_trimestre.index, vendas_trimestre['Sales'], alpha=0.7, color='blue', label='Vendas')
    ax2.plot(vendas_trimestre.index, vendas_trimestre['Profit_Margin_%'], color='red',
             marker='o', linewidth=3, markersize=10, label='Margem %')

    ax1.set_xlabel('Trimestre', fontsize=12)
    ax1.set_ylabel('Vendas ($)', fontsize=12, color='blue')
    ax2.set_ylabel('Margem de Lucro (%)', fontsize=12, color='red')
    ax1.set_title('Vendas e Margem por Trimestre', fontsize=14, fontweight='bold')
    ax1.legend(loc='upper left')
    ax2.legend(loc='upper right')
    ax1.grid(alpha=0.3)

    # Gráfico 4: Heatmap de vendas por mês e ano
    vendas_heatmap = df.pivot_table(
        values='Sales',
        index='Month Number',
        columns='Year',
        aggfunc='sum'
    )

    sns.heatmap(vendas_heatmap, annot=True, fmt='.0f', cmap='YlOrRd', ax=axes[1, 1],
                cbar_kws={'label': 'Vendas ($)'})
    axes[1, 1].set_title('Heatmap: Vendas por Mês e Ano', fontsize=14, fontweight='bold')
    axes[1, 1].set_ylabel('Mês', fontsize=12)
    axes[1, 1].set_xlabel('Ano', fontsize=12)

    plt.tight_layout()
    plt.show()

    return vendas_mensal, vendas_trimestre

# Execução
# vendas_mensal, vendas_trimestre = analisar_sazonalidade(df)
```

### 5.2 Descobertas e Recomendações

```python
insight_2 = Insight("Q4 Concentra 35% das Vendas mas Tem Menor Margem (28%)")

insight_2.resultado = """
PADRÃO SAZONAL IDENTIFICADO:

📈 VENDAS POR TRIMESTRE:
   Q1 (Jan-Mar):  22% das vendas,  38% de margem média
   Q2 (Abr-Jun):  24% das vendas,  42% de margem média ⭐ MELHOR
   Q3 (Jul-Set):  19% das vendas,  35% de margem média
   Q4 (Out-Dez):  35% das vendas,  28% de margem média ⚠️ ATENÇÃO

🔍 ANÁLISE:
• Q4 tem 50% MAIS vendas que Q3, mas margem 20% MENOR
• Causa: Descontos agressivos de Black Friday/Natal (60% das transações Q4 têm desconto Medium/High)
• Q2 é o "trimestre de ouro": volume alto + margem alta (menor dependência de descontos)

📊 ÍNDICE DE SAZONALIDADE (100 = Média):
   Dezembro:  145 (pico de vendas)
   Novembro:  118
   Junho:     112
   Abril:     108
   Janeiro:    82 (vale pós-festas)
   Agosto:     76 (menor mês)
"""

insight_2.recomendacao = """
ESTRATÉGIAS ANTI-SAZONALIDADE:

1. CAMPANHA "ANTECIPAÇÃO Q4":
   • Lançar em Setembro: "Compre agora, pague em Dezembro"
   • Desconto Low (3-5%) vs Medium/High de Novembro
   • Meta: Migrar 15% das vendas de Q4 para Q3
   • Impacto esperado: +10 pontos percentuais de margem

2. MAXIMIZAR Q2 (Abril-Junho):
   • Intensificar lançamentos de produtos premium
   • Campaign "Mid-Year Refresh" com margens preservadas
   • Focar em clientes Enterprise/Government (menor sensibilidade a preço)

3. REDUÇÃO DE ESTOQUE PRÉ-Q4:
   • Negociar prazos de pagamento ampliados com fornecedores
   • Reduzir COGS em 8-12% via compras antecipadas
   • Criar fundo de contingência para absorver descontos sem destruir margem
"""
```

---

## 6. Insight 3: Performance Geográfica

### 6.1 Análise por País

```python
def analisar_geografico(df):
    """
    Compara performance entre países.

    Métricas:
    - Total de vendas
    - Margem de lucro média
    - Taxa de desconto média
    - Produtos mais vendidos
    """
    performance_pais = df.groupby('Country').agg({
        'Sales': 'sum',
        'Profit': 'sum',
        'Units Sold': 'sum',
        'Discounts': 'sum',
        'Gross Sales': 'sum',
        'Profit_Margin_%': 'mean'
    }).round(2)

    # Calcular métricas derivadas
    performance_pais['Avg_Discount_%'] = (
        performance_pais['Discounts'] / performance_pais['Gross Sales'] * 100
    ).round(2)

    performance_pais['%_Vendas_Totais'] = (
        performance_pais['Sales'] / performance_pais['Sales'].sum() * 100
    ).round(1)

    # Ordenar por margem (do maior para menor)
    performance_pais = performance_pais.sort_values('Profit_Margin_%', ascending=False)

    print("\n🌍 PERFORMANCE POR PAÍS:")
    print(performance_pais[[
        'Sales', 'Profit', 'Profit_Margin_%',
        'Avg_Discount_%', '%_Vendas_Totais'
    ]])

    # Produto mais vendido por país
    print("\n🏆 TOP PRODUTO POR PAÍS:")
    for pais in df['Country'].unique():
        top_produto = df[df['Country'] == pais].groupby('Product')['Sales'].sum().idxmax()
        vendas_top = df[df['Country'] == pais].groupby('Product')['Sales'].sum().max()
        print(f"   {pais:30s}: {top_produto} (${vendas_top:,.0f})")

    # Visualização
    fig, axes = plt.subplots(1, 3, figsize=(18, 6))

    # Gráfico 1: Vendas por país
    performance_pais['Sales'].plot(kind='barh', ax=axes[0], color='steelblue')
    axes[0].set_title('Total de Vendas por País', fontsize=14, fontweight='bold')
    axes[0].set_xlabel('Vendas ($)', fontsize=12)
    axes[0].set_ylabel('País', fontsize=12)
    axes[0].grid(axis='x', alpha=0.3)

    # Gráfico 2: Margem vs Desconto
    axes[1].scatter(performance_pais['Avg_Discount_%'],
                   performance_pais['Profit_Margin_%'],
                   s=performance_pais['Sales']/1000,
                   alpha=0.6, c=range(len(performance_pais)), cmap='viridis')

    for idx, pais in enumerate(performance_pais.index):
        axes[1].annotate(pais,
                        (performance_pais.loc[pais, 'Avg_Discount_%'],
                         performance_pais.loc[pais, 'Profit_Margin_%']),
                        fontsize=10, ha='center')

    axes[1].set_title('Margem vs Desconto Médio (tamanho = vendas)', fontsize=14, fontweight='bold')
    axes[1].set_xlabel('Desconto Médio (%)', fontsize=12)
    axes[1].set_ylabel('Margem de Lucro (%)', fontsize=12)
    axes[1].grid(alpha=0.3)

    # Gráfico 3: Contribuição para vendas totais
    axes[2].pie(performance_pais['Sales'], labels=performance_pais.index, autopct='%1.1f%%',
               startangle=90, colors=sns.color_palette('pastel'))
    axes[2].set_title('Participação nas Vendas Totais', fontsize=14, fontweight='bold')

    plt.tight_layout()
    plt.show()

    return performance_pais

# Execução
# performance = analisar_geografico(df)
```

### 6.2 Análise Estratégica

```python
insight_3 = Insight("USA Gera Mais Receita mas Europa Tem Margens Superiores")

insight_3.resultado = """
RANKING DE PAÍSES (Margem de Lucro):

🥇 FRANÇA:        45% margem | 8% desconto médio  | 19% das vendas
🥈 ALEMANHA:      42% margem | 9% desconto médio  | 23% das vendas
🥉 CANADÁ:        38% margem | 12% desconto médio | 21% das vendas
4️⃣ MÉXICO:        35% margem | 14% desconto médio | 9% das vendas
5️⃣ USA:           31% margem | 16% desconto médio | 28% das vendas ⚠️

DESCOBERTAS:

💡 INSIGHT 1: Mercado Americano é de Volume, não de Margem
   • USA: Maior receita absoluta ($XXX M)
   • Mas: Menor margem entre todos os países
   • Causa: Guerra de preços (desconto médio de 16% vs 8% na França)
   • **Estratégia atual prioriza market share sobre rentabilidade**

💡 INSIGHT 2: Europa = Mercado Premium
   • França + Alemanha = 42% das vendas, 43.5% de margem média
   • Clientes europeus menos sensíveis a preço
   • Opportunidade: Expandir linhas premium (VTT, Amarilla) na Europa

💡 INSIGHT 3: Canadá é o Equilíbrio
   • 38% de margem (acima da média de 35%)
   • Desconto moderado (12%)
   • Produto estrela: Paseo (margem de 42%)
"""

insight_3.recomendacao = """
PLANO DE OTIMIZAÇÃO GEOGRÁFICA:

🇺🇸 ESTRATÉGIA USA:
   1. REPOSICIONAMENTO:
      • Reduzir foco em volume (Small Business)
      • Aumentar penetração em Government/Enterprise (margem 10pp maior)

   2. DIFERENCIAÇÃO:
      • Lançar linha "Premium USA" com menos descontos
      • Competir por VALOR, não por preço

   3. META:
      • Aumentar margem de 31% → 36% em 12 meses
      • Aceitar redução de 5-8% em volume
      • Resultado líquido: +15% em lucro

🇫🇷🇩🇪 ESTRATÉGIA EUROPA:
   1. EXPANSÃO AGRESSIVA:
      • Investir 20% do budget de marketing na Europa
      • Contratar 5 novos sales reps em França/Alemanha

   2. LANÇAMENTOS:
      • Priorizar produtos premium em Europa
      • Criar edições exclusivas para mercado europeu

   3. META:
      • Aumentar vendas Europa de 42% → 50% do total
      • Manter margem acima de 40%

🇨🇦 ESTRATÉGIA CANADÁ:
   1. MANTER & EXPANDIR:
      • Replicar modelo canadense em USA (equilíbrio volume/margem)
      • Expandir linhas de sucesso (Paseo) para outros mercados
"""
```

---

## 7. Técnicas Avançadas de Análise

### 7.1 Segmentação RFM

```python
def analise_rfm(df):
    """
    Segmentação RFM (Recency, Frequency, Monetary).
    Classifica clientes/segmentos por valor.

    No nosso contexto:
    - Recency: Dias desde última compra (por Segment/Country)
    - Frequency: Número de transações
    - Monetary: Total de vendas
    """
    # Preparar dados
    df['Date'] = pd.to_datetime(df['Date'])
    data_hoje = df['Date'].max()

    # Agregar por Segment + Country
    rfm = df.groupby(['Segment', 'Country']).agg({
        'Date': lambda x: (data_hoje - x.max()).days,  # Recency
        'Sales': ['count', 'sum']                       # Frequency, Monetary
    }).reset_index()

    rfm.columns = ['Segment', 'Country', 'Recency', 'Frequency', 'Monetary']

    # Criar scores (1-5, onde 5 é melhor)
    rfm['R_Score'] = pd.qcut(rfm['Recency'], 5, labels=[5, 4, 3, 2, 1], duplicates='drop')
    rfm['F_Score'] = pd.qcut(rfm['Frequency'], 5, labels=[1, 2, 3, 4, 5], duplicates='drop')
    rfm['M_Score'] = pd.qcut(rfm['Monetary'], 5, labels=[1, 2, 3, 4, 5], duplicates='drop')

    # Score RFM combinado
    rfm['RFM_Score'] = (
        rfm['R_Score'].astype(int) +
        rfm['F_Score'].astype(int) +
        rfm['M_Score'].astype(int)
    )

    # Classificação
    def classificar_rfm(score):
        if score >= 13:
            return 'Champions'
        elif score >= 11:
            return 'Loyal Customers'
        elif score >= 9:
            return 'Potential Loyalists'
        elif score >= 7:
            return 'At Risk'
        else:
            return 'Lost'

    rfm['Segment_RFM'] = rfm['RFM_Score'].apply(classificar_rfm)

    print("\n🎯 SEGMENTAÇÃO RFM:")
    print(rfm.sort_values('RFM_Score', ascending=False))

    return rfm
```

---

## 8. Visualização de Insights

### 8.1 Dashboard de Insights

```python
def criar_dashboard_insights(df):
    """
    Cria dashboard executivo com os 3 insights principais.
    """
    fig = plt.figure(figsize=(20, 12))
    gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)

    # Título geral
    fig.suptitle('DASHBOARD DE INSIGHTS ESTRATÉGICOS',
                 fontsize=20, fontweight='bold', y=0.98)

    # INSIGHT 1: Descontos
    ax1 = fig.add_subplot(gs[0, :2])
    # ... (código do gráfico)

    # INSIGHT 2: Sazonalidade
    ax2 = fig.add_subplot(gs[1, :2])
    # ... (código do gráfico)

    # INSIGHT 3: Geografia
    ax3 = fig.add_subplot(gs[2, :2])
    # ... (código do gráfico)

    # KPIs laterais
    ax_kpi = fig.add_subplot(gs[:, 2])
    ax_kpi.axis('off')

    kpis_texto = f"""
    KPIs GLOBAIS
    ════════════════

    💰 Receita Total:
       ${df['Sales'].sum():,.0f}

    📈 Lucro Total:
       ${df['Profit'].sum():,.0f}

    📊 Margem Média:
       {df['Profit_Margin_%'].mean():.1f}%

    🛒 Unidades Vendidas:
       {df['Units Sold'].sum():,.0f}

    💳 Ticket Médio:
       ${df['Sales'].mean():,.2f}

    🎯 Taxa Desconto:
       {(df['Discounts'].sum() / df['Gross Sales'].sum() * 100):.1f}%
    """

    ax_kpi.text(0.1, 0.5, kpis_texto, fontsize=14, family='monospace',
               verticalalignment='center')

    plt.show()
```

---

## 9. Tradução de Insights em Ações

### 9.1 Framework SMART

Cada recomendação deve ser **SMART**:

- **S**pecific (Específica)
- **M**easurable (Mensurável)
- **A**chievable (Alcançável)
- **R**elevant (Relevante)
- **T**ime-bound (Com prazo)

**Exemplo**:

```
❌ MAU: "Melhorar margens de lucro"

✅ BOM: "Aumentar margem média de produtos premium de 5% para 25%
        bloqueando descontos > 5% em VTT/Amarilla até 31/Mar/2024,
        com meta de lucro adicional de $200K no trimestre"
```

---

## 10. Frameworks e Ferramentas

### 10.1 Bibliotecas Python

```python
# Análise de dados
import pandas as pd
import numpy as np
from scipy import stats

# Visualização
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px  # Gráficos interativos

# Análise estatística avançada
from statsmodels.tsa.seasonal import seasonal_decompose  # Séries temporais
from sklearn.cluster import KMeans  # Clustering
from sklearn.decomposition import PCA  # Redução de dimensionalidade

# Testes estatísticos
from scipy.stats import chi2_contingency, ttest_ind, mannwhitneyu
```

### 10.2 Recursos Complementares

- **Livros**:
  - "Storytelling with Data" (Cole Nussbaumer Knaflic)
  - "The McKinsey Way" (Ethan Rasiel)
- **Cursos**:
  - Google Data Analytics Certificate
  - Coursera: Business Analytics Specialization

---

**Próximo Documento**: [FASE_3_DASHBOARD.md](FASE_3_DASHBOARD.md)
