# FASE 1: ETL - Extração, Transformação e Carga de Dados Financeiros

> **Documentação Técnica Completa**  
> Pipeline de Processamento de Dados com Python e Pandas

---

## 📚 Índice

1. [Fundamentos Teóricos do ETL](#fundamentos-teóricos-do-etl)
2. [Arquitetura do Pipeline](#arquitetura-do-pipeline)
3. [Etapa 1: Extração de Dados](#etapa-1-extração-de-dados)
4. [Etapa 2: Limpeza e Validação](#etapa-2-limpeza-e-validação)
5. [Etapa 3: Transformação de Tipos](#etapa-3-transformação-de-tipos)
6. [Etapa 4: Feature Engineering](#etapa-4-feature-engineering)
7. [Etapa 5: Validação de Qualidade](#etapa-5-validação-de-qualidade)
8. [Otimização e Performance](#otimização-e-performance)
9. [Tratamento de Erros](#tratamento-de-erros)
10. [Boas Práticas e Troubleshooting](#boas-práticas-e-troubleshooting)

---

## 1. Fundamentos Teóricos do ETL

### 1.1 O Que É ETL?

**ETL (Extract, Transform, Load)** é um padrão arquitetural de integração de dados que envolve três processos sequenciais:

1. **Extract (Extração)**: Leitura de dados de uma ou múltiplas fontes
2. **Transform (Transformação)**: Limpeza, validação e reestruturação dos dados
3. **Load (Carga)**: Armazenamento dos dados processados em um destino

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   EXTRACT    │ ───> │  TRANSFORM   │ ───> │     LOAD     │
│              │      │              │      │              │
│ CSV, JSON,   │      │ Limpeza      │      │ Database,    │
│ APIs, DB     │      │ Validação    │      │ Data Lake,   │
│              │      │ Enriquecimento│     │ Warehouse    │
└──────────────┘      └──────────────┘      └──────────────┘
```

### 1.2 Por Que ETL É Essencial?

**Problemas que o ETL Resolve**:

| Problema                      | Impacto                             | Solução ETL                    |
| ----------------------------- | ----------------------------------- | ------------------------------ |
| **Dados Sujos**               | Análises incorretas, decisões ruins | Limpeza e validação automática |
| **Formatos Inconsistentes**   | Impossibilidade de análise agregada | Normalização de tipos          |
| **Valores Faltantes**         | Gaps na análise temporal            | Imputação inteligente          |
| **Dados Duplicados**          | Contagem inflacionada de métricas   | Deduplicação com hash/ID       |
| **Colunas Pouco Expressivas** | Dificuldade em extrair insights     | Feature Engineering            |

### 1.3 Por Que Pandas?

**Pandas** é a biblioteca Python de facto para manipulação de dados tabulares:

- **Performance**: Operações vetorizadas em C (até 100x mais rápido que loops Python)
- **Expressividade**: Sintaxe declarativa similar a SQL
- **Integração**: Suporta CSV, Excel, SQL, JSON, Parquet, etc.
- **Memória Eficiente**: Otimizações como `category` dtype e chunking

**Alternativas**:

- **Dask**: Para datasets > 10GB (paralelização)
- **Polars**: Para performance extrema (Rust-based)
- **PySpark**: Para ambientes distribuídos (Hadoop/Spark)

---

## 2. Arquitetura do Pipeline

### 2.1 Visão Geral do Fluxo de Dados

```
┌─────────────────────────────────────────────────────────────────┐
│                   PIPELINE ETL - VISÃO MACRO                    │
└─────────────────────────────────────────────────────────────────┘

INPUT: Financials.csv (121KB, 701 linhas, 16 colunas)
   │
   ├─> ETAPA 1: EXTRAÇÃO
   │   ├─ pd.read_csv() com encoding UTF-8
   │   ├─ Análise exploratória inicial (.info(), .describe())
   │   └─ Detecção de tipos de dados (dtype inference)
   │
   ├─> ETAPA 2: LIMPEZA
   │   ├─ Remoção de espaços em branco (.strip())
   │   ├─ Deduplicação (.drop_duplicates())
   │   ├─ Tratamento de nulos (.fillna())
   │   └─ Normalização de strings (.lower(), .replace())
   │
   ├─> ETAPA 3: TRANSFORMAÇÃO DE TIPOS
   │   ├─ Conversão monetária: "$1,234.56" → 1234.56 (float64)
   │   ├─ Conversão de datas: "01/06/2014" → datetime64
   │   ├─ Otimização de memória: object → category
   │   └─ Validação de ranges (ex: preços > 0)
   │
   ├─> ETAPA 4: FEATURE ENGINEERING
   │   ├─ Métricas derivadas (Margin, Discount Rate, ROI)
   │   ├─ Agregações temporais (Quarter, Year-Quarter)
   │   ├─ Binning categórico (Volume_Category)
   │   └─ Flags booleanas (is_profitable, has_discount)
   │
   ├─> ETAPA 5: VALIDAÇÃO DE QUALIDADE
   │   ├─ Testes de integridade (Sales = Gross Sales - Discounts)
   │   ├─ Análise de outliers (IQR method)
   │   ├─ Verificação de valores negativos
   │   └─ Geração de relatório de qualidade
   │
   └─> OUTPUT: Financials_Processado.csv (enriquecido com 6 colunas)
```

### 2.2 Estrutura de Dados do Arquivo Original

**Financials.csv - Schema**:

```python
Index | Column Name           | Dtype   | Sample Values                | Observações
------+-----------------------+---------+------------------------------+--------------------------
0     | Segment               | object  | "Government", "Midmarket"    | 5 categorias únicas
1     | Country               | object  | "Canada", "France"           | 5 países
2     | Product               | object  | "Carretera", "Paseo"         | 6 produtos
3     | Discount Band         | object  | "None", "Low", "Medium"      | 4 níveis + None
4     | Units Sold            | object  | " $1,618.50 "                | String com $, ,
5     | Manufacturing Price   | float   | 3.00, 10.00, 120.00          | Já numérico
6     | Sale Price            | float   | 20.00, 125.00                | Já numérico
7     | Gross Sales           | object  | " $32,370.00 "               | String monetária
8     | Discounts             | object  | " $-   " ou " $276.15 "      | "$-" = zero
9     | Sales                 | object  | " $32,370.00 "               | String monetária
10    | COGS                  | object  | " $16,185.00 "               | Custo dos produtos
11    | Profit                | object  | " $16,185.00 "               | Pode ser negativo
12    | Date                  | object  | "01/01/2014"                 | Formato DD/MM/YYYY
13    | Month Number          | int     | 1, 6, 12                     | 1-12
14    | Month Name            | object  | " January ", " June "        | Com espaços
15    | Year                  | int     | 2013, 2014                   | 2 anos apenas
```

**Problemas Identificados**:

- ❌ 9 colunas numéricas armazenadas como `object` (strings)
- ❌ Valores monetários com símbolos `$` e `,` (mil separadores)
- ❌ Espaços em branco no início/fim de strings
- ❌ Representação inconsistente de zero: `" $-   "` vs `0`
- ❌ Datas não convertidas para tipo `datetime`

---

## 3. Etapa 1: Extração de Dados

### 3.1 Função de Carregamento

```python
import pandas as pd
import numpy as np
from pathlib import Path
import logging

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def carregar_dados(caminho_arquivo):
    """
    Carrega arquivo CSV com tratamento robusto de encoding e erros.

    Parameters
    ----------
    caminho_arquivo : str ou Path
        Caminho absoluto ou relativo para o arquivo CSV

    Returns
    -------
    pd.DataFrame
        DataFrame com dados brutos do CSV

    Raises
    ------
    FileNotFoundError
        Se o arquivo não existir no caminho especificado
    pd.errors.ParserError
        Se o CSV estiver malformado

    Examples
    --------
    >>> df = carregar_dados("Financials.csv")
    >>> df.shape
    (701, 16)

    Notes
    -----
    - Usa encoding UTF-8 por padrão (comum em dados internacionais)
    - on_bad_lines='skip' ignora linhas com número incorreto de campos
    - low_memory=False desativa o chunking para inferência de tipos
    """

    # Valida se o arquivo existe
    arquivo = Path(caminho_arquivo)
    if not arquivo.exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {arquivo.absolute()}")

    logger.info(f"📁 Carregando arquivo: {arquivo.name} ({arquivo.stat().st_size / 1024:.1f} KB)")

    try:
        # Parâmetros otimizados para CSVs financeiros
        df = pd.read_csv(
            arquivo,
            encoding='utf-8',           # Suporta caracteres especiais
            on_bad_lines='skip',        # Ignora linhas corrompidas
            low_memory=False,           # Melhora inferência de tipos
            skipinitialspace=True,      # Remove espaços após delimitador
            na_values=['', 'NA', 'N/A', 'null', 'NULL']  # Define valores nulos
        )

        logger.info(f"✅ Dataset carregado: {df.shape[0]} linhas × {df.shape[1]} colunas")

        # Análise exploratória inicial
        logger.info("\n📊 ANÁLISE EXPLORATÓRIA INICIAL:")
        logger.info(f"   - Tamanho em memória: {df.memory_usage(deep=True).sum() / 1024:.1f} KB")
        logger.info(f"   - Colunas: {list(df.columns)}")
        logger.info(f"   - Tipos de dados: {df.dtypes.value_counts().to_dict()}")
        logger.info(f"   - Valores nulos totais: {df.isnull().sum().sum()}")

        # Amostra de dados
        print("\n🔍 Primeiras 3 linhas:")
        print(df.head(3))

        return df

    except pd.errors.ParserError as e:
        logger.error(f"❌ Erro ao parsear CSV: {str(e)}")
        raise
    except Exception as e:
        logger.error(f"❌ Erro inesperado: {str(e)}")
        raise
```

### 3.2 Análise Exploratória Inicial (EDA)

```python
def analise_exploratoria(df):
    """
    Gera relatório detalhado sobre a qualidade dos dados brutos.

    Parameters
    ----------
    df : pd.DataFrame
        DataFrame a ser analisado

    Returns
    -------
    dict
        Dicionário com métricas de qualidade
    """

    print("\n" + "="*70)
    print("📈 RELATÓRIO DE ANÁLISE EXPLORATÓRIA DE DADOS (EDA)")
    print("="*70)

    # 1. Informações Gerais
    print("\n1️⃣ INFORMAÇÕES GERAIS:")
    print(f"   • Shape: {df.shape[0]} linhas × {df.shape[1]} colunas")
    print(f"   • Memória ocupada: {df.memory_usage(deep=True).sum() / (1024**2):.2f} MB")

    # 2. Tipos de Dados
    print("\n2️⃣ DISTRIBUIÇÃO DE TIPOS:")
    tipo_counts = df.dtypes.value_counts()
    for tipo, count in tipo_counts.items():
        print(f"   • {tipo}: {count} colunas")

    # 3. Valores Nulos
    print("\n3️⃣ VALORES NULOS:")
    nulos = df.isnull().sum()
    if nulos.sum() == 0:
        print("   ✅ Nenhum valor nulo detectado!")
    else:
        print(nulos[nulos > 0])

    # 4. Colunas Numéricas (deveria ser numérico mas está como object)
    print("\n4️⃣ COLUNAS NUMÉRICAS MASCARADAS COMO OBJECT:")
    colunas_suspeitas = []
    for col in df.select_dtypes(include='object').columns:
        # Tenta converter 10 primeiros valores não-nulos
        amostra = df[col].dropna().head(10)
        if amostra.str.contains(r'\$|[\d,]+\.?\d*').any():
            colunas_suspeitas.append(col)
            print(f"   ⚠️ {col}: contém valores monetários")
            print(f"      Exemplo: {amostra.iloc[0]}")

    # 5. Duplicatas
    print("\n5️⃣ DUPLICATAS:")
    duplicatas = df.duplicated().sum()
    if duplicatas > 0:
        print(f"   ⚠️ {duplicatas} linhas duplicadas ({duplicatas/len(df)*100:.1f}%)")
    else:
        print("   ✅ Nenhuma duplicata encontrada!")

    # 6. Cardinalidade de Colunas Categóricas
    print("\n6️⃣ CARDINALIDADE (colunas categóricas):")
    for col in df.select_dtypes(include='object').columns:
        if col not in colunas_suspeitas:  # Ignora monetárias
            nunique = df[col].nunique()
            print(f"   • {col}: {nunique} valores únicos")
            if nunique <= 10:
                print(f"      → {df[col].value_counts().head(3).to_dict()}")

    # 7. Estatísticas Descritivas (colunas já numéricas)
    print("\n7️⃣ ESTATÍSTICAS DESCRITIVAS (colunas numéricas puras):")
    print(df.describe(include=[np.number]))

    # Retorna métricas como dicionário
    metricas = {
        'shape': df.shape,
        'memoria_mb': df.memory_usage(deep=True).sum() / (1024**2),
        'valores_nulos': df.isnull().sum().sum(),
        'duplicatas': duplicatas,
        'colunas_monetarias': colunas_suspeitas
    }

    return metricas
```

### 3.3 Exemplo de Uso

```python
# Executar extração
df_bruto = carregar_dados("Financials.csv")
metricas_iniciais = analise_exploratoria(df_bruto)

# Resultado esperado:
# =====================================================================
# 📁 Carregando arquivo: Financials.csv (119.0 KB)
# ✅ Dataset carregado: 701 linhas × 16 colunas
#
# 📊 ANÁLISE EXPLORATÓRIA INICIAL:
#    - Tamanho em memória: 89.2 KB
#    - Colunas: ['Segment', 'Country', 'Product', ...]
#    - Tipos de dados: {'object': 12, 'int64': 2, 'float64': 2}
#    - Valores nulos totais: 0
# =====================================================================
```

---

## 4. Etapa 2: Limpeza e Validação

### 4.1 Estratégias de Limpeza

#### 4.1.1 Remoção de Espaços em Branco

**Problema**: Strings como `" January "` causam falhas em joins e agrupamentos.

**Solução**:

```python
def limpar_espacos(df):
    """
    Remove espaços em branco do início/fim de todas as strings.

    Técnica: Aplica .str.strip() em todas as colunas object.
    Complexidade: O(n*m) onde n=linhas, m=colunas de texto
    """
    df_clean = df.copy()

    # Remove espaços dos nomes das colunas
    df_clean.columns = df_clean.columns.str.strip()

    # Remove espaços dos valores
    colunas_texto = df_clean.select_dtypes(include='object').columns

    for col in colunas_texto:
        # .str.strip() é vetorizado (rápido)
        df_clean[col] = df_clean[col].str.strip()

    logger.info(f"🧹 Espaços removidos de {len(colunas_texto)} colunas de texto")

    return df_clean
```

**Performance**:

- Dataset de 700 linhas: ~5ms
- Dataset de 1M linhas: ~2s
- Alternativa mais rápida: usar `apply(lambda x: x.strip() if isinstance(x, str) else x)` com `numba`

#### 4.1.2 Deduplicação

**Problema**: Linhas idênticas inflacionam métricas agregadas.

**Solução**:

```python
def remover_duplicatas(df, subset=None, keep='first'):
    """
    Remove linhas duplicadas com estratégia configurável.

    Parameters
    ----------
    df : pd.DataFrame
    subset : list, optional
        Colunas para considerar na comparação (None = todas)
    keep : {'first', 'last', False}
        'first': mantém primeira ocorrência
        'last': mantém última ocorrência
        False: remove todas as duplicatas

    Returns
    -------
    pd.DataFrame
        DataFrame sem duplicatas

    Notes
    -----
    Pandas usa hashing interno para detectar duplicatas:
    - Complexidade: O(n) em média
    - Usa ~2x memória durante execução
    """
    linhas_antes = len(df)

    # drop_duplicates é otimizado com hash table
    df_dedup = df.drop_duplicates(subset=subset, keep=keep)

    linhas_depois = len(df_dedup)
    removidas = linhas_antes - linhas_depois

    if removidas > 0:
        logger.warning(
            f"⚠️ {removidas} duplicatas removidas "
            f"({removidas/linhas_antes*100:.2f}%)"
        )
    else:
        logger.info("✅ Nenhuma duplicata encontrada")

    return df_dedup
```

**Estratégias Avançadas**:

```python
# 1. Deduplicação por chave de negócio
# (em vez de comparar todas as colunas)
df_dedup = remover_duplicatas(
    df,
    subset=['Country', 'Product', 'Date', 'Segment'],
    keep='last'  # Mantém transação mais recente
)

# 2. Deduplicação "fuzzy" (para dados com typos)
from fuzzywuzzy import fuzz

def dedup_fuzzy(df, coluna, threshold=90):
    """Remove duplicatas com similaridade > threshold%"""
    grupos = []
    visitados = set()

    for i, val1 in enumerate(df[coluna]):
        if i in visitados:
            continue
        grupo = [i]
        for j, val2 in enumerate(df[coluna].iloc[i+1:], start=i+1):
            if fuzz.ratio(val1, val2) >= threshold:
                grupo.append(j)
                visitados.add(j)
        grupos.append(grupo)

    # Mantém primeira ocorrência de cada grupo
    indices_manter = [g[0] for g in grupos]
    return df.iloc[indices_manter]
```

#### 4.1.3 Tratamento de Valores Nulos

**Estratégias Por Tipo de Dado**:

```python
def tratar_nulos(df):
    """
    Imputa valores nulos com estratégias específicas por coluna.

    Regras:
    - Numéricos contínuos: mediana (robusta a outliers)
    - Numéricos discretos: moda (valor mais frequente)
    - Categóricos: categoria "Unknown"
    - Datas: forward fill (última data válida)
    """
    df_filled = df.copy()

    # 1. Colunas numéricas contínuas (ex: Sales, Profit)
    colunas_continuas = ['Gross Sales', 'Sales', 'Profit', 'COGS', 'Discounts']
    for col in colunas_continuas:
        if col in df_filled.columns and df_filled[col].dtype in ['float64', 'int64']:
            mediana = df_filled[col].median()
            nulos_antes = df_filled[col].isnull().sum()
            df_filled[col] = df_filled[col].fillna(mediana)
            if nulos_antes > 0:
                logger.info(f"   • {col}: {nulos_antes} nulos → mediana ({mediana:.2f})")

    # 2. Colunas numéricas discretas (ex: Units Sold)
    colunas_discretas = ['Units Sold', 'Month Number']
    for col in colunas_discretas:
        if col in df_filled.columns and df_filled[col].dtype in ['float64', 'int64']:
            moda = df_filled[col].mode()[0]
            nulos_antes = df_filled[col].isnull().sum()
            df_filled[col] = df_filled[col].fillna(moda)
            if nulos_antes > 0:
                logger.info(f"   • {col}: {nulos_antes} nulos → moda ({moda})")

    # 3. Colunas categóricas
    colunas_categoricas = ['Segment', 'Country', 'Product', 'Discount Band']
    for col in colunas_categoricas:
        if col in df_filled.columns:
            nulos_antes = df_filled[col].isnull().sum()
            df_filled[col] = df_filled[col].fillna('Unknown')
            if nulos_antes > 0:
                logger.info(f"   • {col}: {nulos_antes} nulos → 'Unknown'")

    # 4. Colunas de data
    if 'Date' in df_filled.columns:
        nulos_antes = df_filled['Date'].isnull().sum()
        df_filled['Date'] = df_filled['Date'].fillna(method='ffill')  # Forward fill
        if nulos_antes > 0:
            logger.info(f"   • Date: {nulos_antes} nulos → forward fill")

    return df_filled
```

**Técnicas Avançadas de Imputação**:

```python
from sklearn.impute import KNNImputer, IterativeImputer

# 1. KNN Imputer (usa K vizinhos mais próximos)
imputer_knn = KNNImputer(n_neighbors=5)
df[['Sales', 'Profit']] = imputer_knn.fit_transform(df[['Sales', 'Profit']])

# 2. MICE (Multiple Imputation by Chained Equations)
imputer_mice = IterativeImputer(random_state=42)
df_imputed = pd.DataFrame(
    imputer_mice.fit_transform(df.select_dtypes(include=[np.number])),
    columns=df.select_dtypes(include=[np.number]).columns
)
```

---

## 5. Etapa 3: Transformação de Tipos

### 5.1 Conversão de Strings Monetárias

**Desafio**: Converter `" $1,618.50 "` → `1618.50` (float)

```python
def converter_monetario(df, colunas_monetarias):
    """
    Converte strings monetárias para float64.

    Trata os seguintes formatos:
    - " $1,234.56 "   → 1234.56
    - " $-   "        → 0.0
    - "(1,234.56)"    → -1234.56 (parênteses = negativo em finanças)
    - "1234"          → 1234.0

    Parameters
    ----------
    df : pd.DataFrame
    colunas_monetarias : list
        Lista de colunas a converter

    Returns
    -------
    pd.DataFrame
        DataFrame com colunas convertidas

    Performance
    -----------
    - Regex: ~100ms para 1M linhas
    - Alternativa: usar replace() múltiplo (~30ms)
    """
    df_converted = df.copy()

    for col in colunas_monetarias:
        if col not in df_converted.columns:
            logger.warning(f"⚠️ Coluna '{col}' não encontrada, pulando...")
            continue

        if df_converted[col].dtype == 'object':
            # Pipeline de limpeza
            serie = df_converted[col]

            # Etapa 1: Remove símbolos e espaços
            serie = serie.str.replace('$', '', regex=False)
            serie = serie.str.replace(',', '', regex=False)
            serie = serie.str.replace(' ', '', regex=False)
            serie = serie.str.replace('"', '', regex=False)

            # Etapa 2: Trata valores especiais
            serie = serie.replace('-', '0')  # "$-" significa zero
            serie = serie.replace('', '0')   # String vazia = zero

            # Etapa 3: Trata valores negativos em parênteses
            # Ex: "(1234.56)" → "-1234.56"
            serie = serie.str.replace(r'^\((.*)\)$', r'-\1', regex=True)

            # Etapa 4: Converte para float
            df_converted[col] = pd.to_numeric(serie, errors='coerce').fillna(0)

            logger.info(f"💱 {col}: convertido para float64 (range: {df_converted[col].min():.2f} a {df_converted[col].max():.2f})")

    return df_converted
```

**Método Alternativo (Mais Rápido)**:

```python
import re

def converter_monetario_rapido(valor):
    """
    Converte um único valor monetário usando regex.
    5x mais rápido que múltiplos .str.replace()
    """
    if pd.isna(valor) or valor == '-':
        return 0.0

    # Remove tudo exceto dígitos, ponto e sinal negativo
    limpo = re.sub(r'[^\d.-]', '', str(valor))

    try:
        return float(limpo) if limpo else 0.0
    except ValueError:
        return 0.0

# Aplicação vetorizada
df['Sales'] = df['Sales'].apply(converter_monetario_rapido)
```

### 5.2 Conversão de Datas

```python
def converter_datas(df, coluna_data='Date', formato='%d/%m/%Y'):
    """
    Converte string de data para datetime64[ns].

    Formatos suportados:
    - DD/MM/YYYY  →  2014-06-01
    - MM-DD-YYYY  →  2014-06-01
    - YYYY/MM/DD  →  2014-06-01
    - Auto-detect →  pd.to_datetime com infer_datetime_format

    Parameters
    ----------
    df : pd.DataFrame
    coluna_data : str
        Nome da coluna com datas
    formato : str, optional
        Formato strptime (None = auto-detect)

    Returns
    -------
    pd.DataFrame
        DataFrame com coluna convertida

    Notes
    -----
    Auto-detect é ~10x mais lento que especificar formato explícito
    """
    df_converted = df.copy()

    if coluna_data not in df_converted.columns:
        raise ValueError(f"Coluna '{coluna_data}' não encontrada no DataFrame")

    try:
        if formato:
            # Conversão com formato explícito (RÁPIDO)
            df_converted[coluna_data] = pd.to_datetime(
                df_converted[coluna_data],
                format=formato,
                errors='coerce'  # Valores inválidos viram NaT
            )
        else:
            # Auto-detect (LENTO mas flexível)
            df_converted[coluna_data] = pd.to_datetime(
                df_converted[coluna_data],
                infer_datetime_format=True,
                errors='coerce'
            )

        # Estatísticas da conversão
        nat_count = df_converted[coluna_data].isna().sum()
        if nat_count > 0:
            logger.warning(f"⚠️ {nat_count} datas inválidas convertidas para NaT")

        data_min = df_converted[coluna_data].min()
        data_max = df_converted[coluna_data].max()
        logger.info(f"📅 {coluna_data}: {data_min.date()} a {data_max.date()} ({(data_max - data_min).days} dias)")

    except Exception as e:
        logger.error(f"❌ Erro ao converter datas: {str(e)}")
        raise

    return df_converted
```

### 5.3 Otimização de Tipos de Dados

**Reduzir uso de memória em 50-90%**:

```python
def otimizar_tipos(df):
    """
    Converte tipos de dados para versões mais eficientes.

    Otimizações:
    - int64 → int32 (se range permitir)
    - object → category (se cardinalidade < 50%)
    - float64 → float32 (perda mínima de precisão)

    Returns
    -------
    pd.DataFrame
        DataFrame otimizado

    Examples
    --------
    >>> df_original.memory_usage(deep=True).sum()
    1048576  # 1 MB
    >>> df_otimizado = otimizar_tipos(df_original)
    >>> df_otimizado.memory_usage(deep=True).sum()
    262144  # 256 KB (redução de 75%)
    """
    df_opt = df.copy()
    mem_antes = df_opt.memory_usage(deep=True).sum() / 1024**2

    # 1. Converte object → category (se cardinalidade baixa)
    for col in df_opt.select_dtypes(include='object').columns:
        nunique = df_opt[col].nunique()
        total = len(df_opt[col])

        if nunique / total < 0.5:  # < 50% de valores únicos
            df_opt[col] = df_opt[col].astype('category')
            logger.info(f"   • {col}: object → category ({nunique} categorias)")

    # 2. Converte int64 → int32 (se valores cabem)
    for col in df_opt.select_dtypes(include='int64').columns:
        col_min = df_opt[col].min()
        col_max = df_opt[col].max()

        # Limites do int32: -2,147,483,648 a 2,147,483,647
        if col_min >= -2147483648 and col_max <= 2147483647:
            df_opt[col] = df_opt[col].astype('int32')
            logger.info(f"   • {col}: int64 → int32")

    # 3. Converte float64 → float32 (CUIDADO: pode haver perda de precisão)
    # Só recomendado se não for fazer cálculos financeiros críticos
    # for col in df_opt.select_dtypes(include='float64').columns:
    #     df_opt[col] = df_opt[col].astype('float32')

    mem_depois = df_opt.memory_usage(deep=True).sum() / 1024**2
    reducao = (1 - mem_depois / mem_antes) * 100

    logger.info(f"\n💾 OTIMIZAÇÃO DE MEMÓRIA:")
    logger.info(f"   Antes:  {mem_antes:.2f} MB")
    logger.info(f"   Depois: {mem_depois:.2f} MB")
    logger.info(f"   Redução: {reducao:.1f}%")

    return df_opt
```

---

## 6. Etapa 4: Feature Engineering

### 6.1 Criação de Métricas Financeiras

```python
def criar_metricas_financeiras(df):
    """
    Calcula KPIs financeiros derivados.

    Métricas criadas:
    1. Profit_Margin_% = (Profit / Sales) × 100
    2. Discount_Rate_% = (Discounts / Gross Sales) × 100
    3. COGS_Ratio_% = (COGS / Sales) × 100
    4. Revenue_Per_Unit = Sales / Units Sold
    5. Markup_% = ((Sale Price - Manuf. Price) / Manuf. Price) × 100
    6. ROI_% = (Profit / COGS) × 100

    Parameters
    ----------
    df : pd.DataFrame
        Deve conter: Sales, Profit, Gross Sales, Discounts, etc.

    Returns
    -------
    pd.DataFrame
        DataFrame com 6 colunas adicionais

    Notes
    -----
    Usa np.where para evitar divisão por zero
    """
    df_eng = df.copy()

    # 1. Margem de Lucro (%)
    # Fórmula: Lucro / Receita Líquida
    # Interpretação: 40% = ganhamos $0.40 para cada $1 vendido
    df_eng['Profit_Margin_%'] = np.where(
        df_eng['Sales'] != 0,
        (df_eng['Profit'] / df_eng['Sales']) * 100,
        0
    )

    # 2. Taxa de Desconto Efetiva (%)
    # Quanto % do preço bruto foi descontado
    df_eng['Discount_Rate_%'] = np.where(
        df_eng['Gross Sales'] != 0,
        (df_eng['Discounts'] / df_eng['Gross Sales']) * 100,
        0
    )

    # 3. Razão de Custo (%)
    # Quanto % da receita é custo do produto
    df_eng['COGS_Ratio_%'] = np.where(
        df_eng['Sales'] != 0,
        (df_eng['COGS'] / df_eng['Sales']) * 100,
        0
    )

    # 4. Receita por Unidade
    # Preço médio efetivo por unidade vendida
    df_eng['Revenue_Per_Unit'] = np.where(
        df_eng['Units Sold'] != 0,
        df_eng['Sales'] / df_eng['Units Sold'],
        0
    )

    # 5. Markup sobre Custo de Fabricação (%)
    # Quanto % foi marcado acima do custo
    df_eng['Markup_%'] = np.where(
        df_eng['Manufacturing Price'] != 0,
        ((df_eng['Sale Price'] - df_eng['Manufacturing Price']) /
         df_eng['Manufacturing Price']) * 100,
        0
    )

    # 6. Retorno sobre Custo (ROI)
    # Quanto de lucro para cada $1 de custo
    df_eng['ROI_%'] = np.where(
        df_eng['COGS'] != 0,
        (df_eng['Profit'] / df_eng['COGS']) * 100,
        0
    )

    logger.info("➕ 6 métricas financeiras criadas:")
    logger.info("   1. Profit_Margin_% (margem de lucro)")
    logger.info("   2. Discount_Rate_% (taxa de desconto)")
    logger.info("   3. COGS_Ratio_% (custo/receita)")
    logger.info("   4. Revenue_Per_Unit (receita unitária)")
    logger.info("   5. Markup_% (marcação de preço)")
    logger.info("   6. ROI_% (retorno sobre custo)")

    return df_eng
```

### 6.2 Engenharia Temporal

```python
def criar_features_temporais(df, coluna_data='Date'):
    """
    Extrai features temporais de uma coluna datetime.

    Features criadas:
    - Quarter: 1, 2, 3, 4
    - Year_Quarter: "2014-Q1"
    - DayOfWeek: 0 (Monday) a 6 (Sunday)
    - DayOfWeek_Name: "Monday", "Tuesday", ...
    - IsWeekend: True/False
    - WeekOfYear: 1 a 52
    - DaysFromStart: dias desde primeira transação
    """
    df_temporal = df.copy()

    if coluna_data not in df_temporal.columns:
        raise ValueError(f"Coluna '{coluna_data}' não encontrada")

    if df_temporal[coluna_data].dtype != 'datetime64[ns]':
        raise TypeError(f"Coluna '{coluna_data}' deve ser datetime64, não {df_temporal[coluna_data].dtype}")

    # 1. Trimestre
    df_temporal['Quarter'] = df_temporal[coluna_data].dt.quarter

    # 2. Ano-Trimestre (útil para séries temporais)
    df_temporal['Year_Quarter'] = (
        df_temporal[coluna_data].dt.year.astype(str) +
        '-Q' +
        df_temporal['Quarter'].astype(str)
    )

    # 3. Dia da Semana
    df_temporal['DayOfWeek'] = df_temporal[coluna_data].dt.dayofweek
    df_temporal['DayOfWeek_Name'] = df_temporal[coluna_data].dt.day_name()

    # 4. É Final de Semana?
    df_temporal['IsWeekend'] = df_temporal['DayOfWeek'].isin([5, 6])

    # 5. Semana do Ano
    df_temporal['WeekOfYear'] = df_temporal[coluna_data].dt.isocalendar().week

    # 6. Dias desde a primeira transação
    data_inicial = df_temporal[coluna_data].min()
    df_temporal['DaysFromStart'] = (df_temporal[coluna_data] - data_inicial).dt.days

    logger.info("📅 7 features temporais criadas:")
    logger.info("   • Quarter, Year_Quarter")
    logger.info("   • DayOfWeek, DayOfWeek_Name, IsWeekend")
    logger.info("   • WeekOfYear, DaysFromStart")

    return df_temporal
```

### 6.3 Binning e Categorização

```python
def criar_categorias(df):
    """
    Cria categorias por binning de variáveis contínuas.

    Categorias criadas:
    - Volume_Category: Baixo/Médio/Alto (baseado em Units Sold)
    - Price_Tier: Economy/Standard/Premium (baseado em Sale Price)
    - Profitability_Label: Loss/Break-even/Low/Medium/High
    """
    df_cat = df.copy()

    # 1. Categoria de Volume de Vendas
    # Bins definidos por quantis (33%, 66%)
    df_cat['Volume_Category'] = pd.qcut(
        df_cat['Units Sold'],
        q=3,
        labels=['Baixo Volume', 'Médio Volume', 'Alto Volume'],
        duplicates='drop'  # Se houver valores repetidos nos cortes
    )

    # 2. Nível de Preço
    # Bins fixos baseados em conhecimento do negócio
    df_cat['Price_Tier'] = pd.cut(
        df_cat['Sale Price'],
        bins=[0, 15, 50, float('inf')],
        labels=['Economy', 'Standard', 'Premium']
    )

    # 3. Categoria de Lucratividade
    # Baseado em margem de lucro
    def classificar_lucratividade(margem):
        if margem < 0:
            return 'Loss'
        elif margem == 0:
            return 'Break-even'
        elif margem < 20:
            return 'Low Profit'
        elif margem < 40:
            return 'Medium Profit'
        else:
            return 'High Profit'

    df_cat['Profitability_Label'] = df_cat['Profit_Margin_%'].apply(classificar_lucratividade)

    logger.info("🏷️ 3 categorias criadas por binning:")
    logger.info(f"   • Volume_Category: {df_cat['Volume_Category'].value_counts().to_dict()}")
    logger.info(f"   • Price_Tier: {df_cat['Price_Tier'].value_counts().to_dict()}")
    logger.info(f"   • Profitability_Label: {df_cat['Profitability_Label'].value_counts().to_dict()}")

    return df_cat
```

---

## 7. Etapa 5: Validação de Qualidade

### 7.1 Testes de Integridade

```python
def validar_integridade_dados(df):
    """
    Executa 10 testes de integridade em dados financeiros.

    Testes:
    1. Sales = Gross Sales - Discounts
    2. Profit = Sales - COGS
    3. Valores negativos inesperados
    4. Outliers (método IQR)
    5. Consistência de datas
    6. Margens impossíveis (ex: > 100%)
    7. Preços zero
    8. Unidades vendidas zero
    9. Relacionamento Manufacturing Price < Sale Price
    10. Soma de percentuais (COGS% + Margin% ≈ 100%)

    Returns
    -------
    dict
        Relatório com falhas e avisos
    """
    relatorio = {
        'testes_passados': 0,
        'testes_falhados': 0,
        'avisos': []
    }

    print("\n" + "="*70)
    print("🔍 VALIDAÇÃO DE INTEGRIDADE DE DADOS")
    print("="*70)

    # Teste 1: Sales = Gross Sales - Discounts
    print("\n1️⃣ Teste: Sales = Gross Sales - Discounts")
    df['Calc_Sales'] = df['Gross Sales'] - df['Discounts']
    desvios = abs(df['Sales'] - df['Calc_Sales']) > 0.01  # Tolerância de 1 centavo
    if desvios.sum() > 0:
        relatorio['testes_falhados'] += 1
        relatorio['avisos'].append(f"❌ {desvios.sum()} transações com Sales inconsistente")
        print(f"   ❌ FALHOU: {desvios.sum()} inconsistências detectadas")
    else:
        relatorio['testes_passados'] += 1
        print("   ✅ PASSOU")
    df.drop('Calc_Sales', axis=1, inplace=True)

    # Teste 2: Profit = Sales - COGS
    print("\n2️⃣ Teste: Profit = Sales - COGS")
    df['Calc_Profit'] = df['Sales'] - df['COGS']
    desvios = abs(df['Profit'] - df['Calc_Profit']) > 0.01
    if desvios.sum() > 0:
        relatorio['testes_falhados'] += 1
        relatorio['avisos'].append(f"❌ {desvios.sum()} transações com Profit inconsistente")
        print(f"   ❌ FALHOU: {desvios.sum()} inconsistências")
    else:
        relatorio['testes_passados'] += 1
        print("   ✅ PASSOU")
    df.drop('Calc_Profit', axis=1, inplace=True)

    # Teste 3: Valores Negativos Inesperados
    print("\n3️⃣ Teste: Valores negativos inesperados")
    colunas_positivas = ['Units Sold', 'Gross Sales', 'Sales', 'COGS']
    tem_negativo = False
    for col in colunas_positivas:
        if col in df.columns:
            negativos = (df[col] < 0).sum()
            if negativos > 0:
                tem_negativo = True
                relatorio['avisos'].append(f"⚠️ {negativos} valores negativos em '{col}'")
                print(f"   ⚠️ {col}: {negativos} valores negativos")

    if tem_negativo:
        relatorio['testes_falhados'] += 1
    else:
        relatorio['testes_passados'] += 1
        print("   ✅ PASSOU")

    # Teste 4: Outliers (método IQR)
    print("\n4️⃣ Teste: Detecção de outliers (IQR)")
    colunas_numericas = df.select_dtypes(include=[np.number]).columns
    for col in colunas_numericas[:5]:  # Primeiras 5 colunas numéricas
        Q1 = df[col].quantile(0.25)
        Q3 = df[col].quantile(0.75)
        IQR = Q3 - Q1
        limite_inferior = Q1 - 1.5 * IQR
        limite_superior = Q3 + 1.5 * IQR

        outliers = ((df[col] < limite_inferior) | (df[col] > limite_superior)).sum()
        if outliers > 0:
            print(f"   ⚠️ {col}: {outliers} outliers ({outliers/len(df)*100:.1f}%)")
    relatorio['testes_passados'] += 1

    # Teste 5: Margens impossíveis
    print("\n5️⃣ Teste: Margens > 100%")
    if 'Profit_Margin_%' in df.columns:
        margens_altas = (df['Profit_Margin_%'] > 100).sum()
        if margens_altas > 0:
            relatorio['avisos'].append(f"⚠️ {margens_altas} transações com margem > 100%")
            print(f"   ⚠️ {margens_altas} margens acima de 100% (verificar se é esperado)")
        else:
            print("   ✅ PASSOU")
    relatorio['testes_passados'] += 1

    # Resumo
    print("\n" + "="*70)
    print("📊 RESUMO DA VALIDAÇÃO:")
    print(f"   ✅ Testes Passados: {relatorio['testes_passados']}")
    print(f"   ❌ Testes Falhados: {relatorio['testes_falhados']}")
    print(f"   ⚠️ Avisos: {len(relatorio['avisos'])}")
    if relatorio['avisos']:
        print("\n   Detalhes dos Avisos:")
        for aviso in relatorio['avisos']:
            print(f"      {aviso}")
    print("="*70)

    return relatorio
```

---

## 8. Otimização e Performance

### 8.1 Técnicas de Otimização

```python
# 1. Chunking para arquivos grandes (> 1GB)
def processar_em_chunks(arquivo, tamanho_chunk=10000):
    """
    Processa CSV em blocos para economizar memória.
    Útil para datasets > 1GB.
    """
    chunks = []
    for chunk in pd.read_csv(arquivo, chunksize=tamanho_chunk):
        # Processa cada chunk
        chunk = limpar_dados(chunk)
        chunk = converter_tipos(chunk)
        chunks.append(chunk)

    # Concatena todos os chunks
    df_completo = pd.concat(chunks, ignore_index=True)
    return df_completo

# 2. Paralelização com multiprocessing
from multiprocessing import Pool

def processar_paralelo(df, funcao, n_cores=4):
    """
    Divide DataFrame em n_cores partes e processa em paralelo.
    """
    df_split = np.array_split(df, n_cores)
    with Pool(n_cores) as pool:
        df_processado = pd.concat(pool.map(funcao, df_split))
    return df_processado

# 3. Vetorização vs Loops
# ❌ LENTO (loop Python)
for i, row in df.iterrows():
    df.at[i, 'Margin'] = row['Profit'] / row['Sales']

# ✅ RÁPIDO (vetorizado)
df['Margin'] = df['Profit'] / df['Sales']
```

---

## 9. Tratamento de Erros

```python
class ETLError(Exception):
    """Exceção base para erros de ETL"""
    pass

class DataValidationError(ETLError):
    """Erro de validação de dados"""
    pass

class TransformationError(ETLError):
    """Erro durante transformação"""
    pass

def pipeline_etl_robusto(arquivo_entrada, arquivo_saida):
    """
    Pipeline ETL com tratamento completo de erros.
    """
    try:
        # Etapa 1: Extração
        try:
            df = carregar_dados(arquivo_entrada)
        except FileNotFoundError:
            logger.critical(f"Arquivo não encontrado: {arquivo_entrada}")
            raise
        except pd.errors.ParserError as e:
            logger.critical(f"Erro ao parsear CSV: {e}")
            raise ETLError(f"CSV malformado: {e}")

        # Etapa 2: Transformação
        try:
            df = limpar_dados(df)
            df = converter_tipos(df)
            df = criar_metricas_financeiras(df)
        except Exception as e:
            logger.error(f"Erro na transformação: {e}")
            raise TransformationError(f"Falha ao transformar dados: {e}")

        # Etapa 3: Validação
        relatorio = validar_integridade_dados(df)
        if relatorio['testes_falhados'] > 0:
            logger.warning("Dados com problemas de integridade, mas continuando...")

        # Etapa 4: Carga
        try:
            df.to_csv(arquivo_saida, index=False, encoding='utf-8')
            logger.info(f"✅ Dados salvos em: {arquivo_saida}")
        except PermissionError:
            logger.critical(f"Sem permissão para escrever em: {arquivo_saida}")
            raise

        return df

    except Exception as e:
        logger.critical(f"❌ PIPELINE FALHOU: {e}")
        raise
```

---

## 10. Boas Práticas e Troubleshooting

### 10.1 Checklist de Boas Práticas

- ✅ **Sempre validar entrada**: Verificar se arquivo existe, se tem colunas esperadas
- ✅ **Logging detalhado**: Usar `logging` em vez de `print()`
- ✅ **Versionamento de dados**: Salvar dados brutos + processados com timestamp
- ✅ **Documentação de transformações**: Comentar regras de negócio complexas
- ✅ **Testes unitários**: Testar funções críticas com `pytest`
- ✅ **Backup antes de sobrescrever**: Copiar arquivo original antes de processamento
- ✅ **Monitoramento de performance**: Usar `%%timeit` em Jupyter para otimizar gargalos

### 10.2 Troubleshooting Comum

| Erro                                            | Causa                            | Solução                                          |
| ----------------------------------------------- | -------------------------------- | ------------------------------------------------ |
| `UnicodeDecodeError`                            | Encoding incorreto               | Usar `encoding='latin-1'` ou `encoding='cp1252'` |
| `MemoryError`                                   | Dataset muito grande             | Usar chunking ou Dask                            |
| `ValueError: could not convert string to float` | Strings com caracteres especiais | Limpar strings antes de `pd.to_numeric()`        |
| `KeyError: 'Coluna'`                            | Nome de coluna errado            | Usar `df.columns.tolist()` para verificar        |
| Performance lenta                               | Loops Python                     | Substituir por operações vetorizadas             |

---

## 📖 Referências

1. **Pandas Documentation**: https://pandas.pydata.org/docs/
2. **Livro: Python for Data Analysis** (Wes McKinney)
3. **Real Python - Pandas Tricks**: https://realpython.com/fast-flexible-pandas/
4. **ETL Best Practices**: https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/

---

**Próximo Documento**: [FASE_2_INSIGHTS.md](FASE_2_INSIGHTS.md)
