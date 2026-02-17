# Scripts de Produção - Financial Data Fortress 2026

Este diretório contém os 5 scripts Python production-ready do projeto.

## 📜 Scripts Disponíveis

### 1. `validate_bronze_quality.py`

**Persona**: Data Quality Engineer  
**Propósito**: Validação da Camada Bronze com Great Expectations

**Validações**:

- ✅ Schema de 16 colunas obrigatórias
- ✅ Detecção de Lakhs/Crores
- ✅ Detecção de `$-` em Discounts
- ✅ Detecção de parênteses em Profit
- ✅ Detecção de caracteres invisíveis

**Uso**:

```bash
python scripts/validate_bronze_quality.py
```

---

### 2. `transform_bronze_to_silver.py`

**Persona**: Senior ETL Developer  
**Propósito**: Limpeza semântica Bronze → Silver

**Transformações**:

1. Normalização de cabeçalhos (snake_case)
2. Parsing monetário (Lakhs/Crores)
3. Polaridade contábil (parênteses)
4. Padronização de datas (ISO-8601)

**Uso**:

```bash
python scripts/transform_bronze_to_silver.py
```

---

### 3. `build_star_schema.py`

**Persona**: Analytics Architect  
**Propósito**: Modelagem dimensional Gold

**Outputs**:

- dim_produto.csv
- dim_geografia.csv
- dim_segmento.csv
- dim_desconto.csv
- dim_tempo.csv (731 datas)
- fato_financeiro.csv

**Uso**:

```bash
python scripts/build_star_schema.py
```

---

### 4. `data_reliability_monitor.py`

**Persona**: Data Reliability Engineer (SRE)  
**Propósito**: Contratos, Incremental Load e Root Cause Analysis

**Funcionalidades**:

- Data Contracts com Pydantic
- Carga incremental (CDC)
- Detecção de anomalias
- Alertas JSON automatizados

**Uso**:

```bash
python scripts/data_reliability_monitor.py
```

---

### 5. `security_vault.py`

**Persona**: Chief Security Officer (CSO)  
**Propósito**: Criptografia e Auditoria Forense

**Funcionalidades**:

- Criptografia AES-256 (Fernet)
- Anonimização SHA-256
- Decorador `@audit_log`
- Logs indeléveis

**Uso**:

```bash
python scripts/security_vault.py
```

---

## 🔄 Pipeline Completo

Execute os scripts em sequência:

```bash
# Etapa 1: Validação
python scripts/validate_bronze_quality.py

# Etapa 2: Transformação
python scripts/transform_bronze_to_silver.py

# Etapa 3: Modelagem
python scripts/build_star_schema.py

# Etapa 4: Monitoramento
python scripts/data_reliability_monitor.py

# Etapa 5: Demo de Segurança
python scripts/security_vault.py
```

---

**Total de Linhas**: ~2.000+ linhas de código Python  
**Cobertura**: Bronze → Silver → Gold + SRE + Security
