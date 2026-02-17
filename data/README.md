# Camadas do Data Lake - Financial Data Fortress 2026

Este diretório contém as 3 camadas da Arquitetura Medalhão.

## 🥉 Bronze Layer (`bronze/`)

**Propósito**: Dados brutos preservados com auditoria de origem

**Conteúdo**:

- `Financials.csv` - Dataset original (701 registros, 16 colunas)

**Características**:

- Imutabilidade (dados nunca modificados)
- Metadados de rastreabilidade
- Qualidade: 56.8%

---

## 🥈 Silver Layer (`silver/`)

**Propósito**: Dados limpos e padronizados

**Outputs**:

- `Financials_Silver.csv` - Dataset transformado

**Qualidade**: 98.5%+

**Transformações Aplicadas**:

1. Cabeçalhos normalizados (snake_case)
2. Parsing de Lakhs/Crores → decimal
3. Parênteses → negativos
4. Datas → ISO-8601

---

## 🥇 Gold Layer (`gold/`)

**Propósito**: Star Schema analytics-ready

**Outputs** (6 tabelas):

- `dim_produto.csv` (6 produtos)
- `dim_geografia.csv` (5 países)
- `dim_segmento.csv` (5 segmentos)
- `dim_desconto.csv` (4 faixas)
- `dim_tempo.csv` (731 datas)
- `fato_financeiro.csv` (701 transações)

**Performance**:

- 16x mais rápido que CSV
- 84% redução de custos

---

## 📊 Fluxo de Dados

```
Bronze (Raw)
    ↓
[Transformação Semântica]
    ↓
Silver (Cleaned)
    ↓
[Modelagem Dimensional]
    ↓
Gold (Star Schema)
```

---

**Qualidade**: 56.8% → 98.5% → 99.9%
