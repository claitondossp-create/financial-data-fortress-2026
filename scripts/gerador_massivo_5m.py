# === FASE 1: ESCALONAMENTO DO DATASET Ouro (Toy -> 5 Milhoes de linhas) ===
import pandas as pd
import numpy as np
import datetime
import os

print("Iniciando geracao massiva de dados para Fato Financeiro...")

# Caminhos absolutos do projeto Ouro
BASE_DIR = r"C:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\data\03_gold"
INPUT_CSV = os.path.join(BASE_DIR, "fato_financeiro.csv")
OUTPUT_PARQUET = os.path.join(BASE_DIR, "fato_financeiro_5M.parquet")
OUTPUT_CSV_VERIFICACAO = os.path.join(BASE_DIR, "fato_financeiro_amostra.csv")

# 1. Carregar DataSet cru de 700 linhas
try:
    df_base = pd.read_csv(INPUT_CSV)
    print(f"Dataset original carregado: {len(df_base)} linhas.")
except Exception as e:
    print(f"Erro ao ler CSV base: {e}")
    exit(1)

# FATOR DE MULTIPLICAÇÃO (700 * 7150 = ~5.000.000 linhas)
# Reduzido de 10M pra 5M pra rodar rapido no teste, o Parquet vai ficar com cerca de 100MB
MULTIPLICADOR = 7150 

print(f"Multiplicando dados base em {MULTIPLICADOR}x ...")
df_massivo = pd.concat([df_base] * MULTIPLICADOR, ignore_index=True)

# Tamanho gerado
total_linhas = len(df_massivo)
print(f"Dataset em memoria: {total_linhas:,.0f} linhas.")

# 2. Adicionar Redundância Realista com Numpy Vectorization (Extreme Performance)
print("Gerando variancia estocastica nos numeros financeiros (Numpy)...")
np.random.seed(42)

# Variação condicional de Vendas (-20% a +40%)
variancia_multiplicador = np.random.uniform(0.8, 1.4, size=total_linhas)

# Modificando as colunas monetarias
df_massivo['unidades_vendidas'] = (df_massivo['unidades_vendidas'] * variancia_multiplicador).astype(int)
df_massivo['receita_liquida'] = (df_massivo['receita_liquida'] * variancia_multiplicador).astype(int)
df_massivo['custo_produtos_vendidos'] = (df_massivo['custo_produtos_vendidos'] * variancia_multiplicador).astype(int)
# Mantendo o lucro coerente com a variancia de receita/custos
df_massivo['lucro'] = df_massivo['receita_liquida'] - df_massivo['custo_produtos_vendidos']

# 3. Reescrever Sk temporais randômicos (2013-2015) para aumentar diversidade de Data
print("Gerando dispersao de IDs e Datas...")
# Remapear IDs 
df_massivo['fato_financeiro_sk'] = np.arange(1, total_linhas + 1)

# Datas unicas na Dim Tempo = 2013-01-01 a 2014-12-31 (como o Power Query agora gera)
# As Sks vao de 20130101 ate 20141201 no formato YYYYMMDD
# vamos simplificar fazendo sample de arrays de chaves_tempo
chaves_tempo_base = df_base['tempo_sk'].unique()
# Random choice of random time keys to overwrite
random_tempos = np.random.choice(chaves_tempo_base, size=total_linhas)
df_massivo['tempo_sk'] = random_tempos

# 4. Salvar como PARQUET Otimizado e uma pequena amostra CSV
print("Salvando arquivo Parquet colunar...")
# Converter as chaves Sk que devem ser numeros pra Int64 (evita float nans no SSAS)
int_cols = ['fato_financeiro_sk', 'produto_sk', 'geografia_sk', 'segmento_sk', 
            'tempo_sk', 'unidades_vendidas', 'receita_liquida', 'custo_produtos_vendidos', 'lucro']
for c in int_cols:
    df_massivo[c] = df_massivo[c].astype('Int64')

# Exportação Rápida via PyArrow engine
try:
    df_massivo.to_parquet(OUTPUT_PARQUET, engine='pyarrow', compression='snappy')
    print(f"✅ EXPORT CONCLUÍDO: {OUTPUT_PARQUET}")
    
    # Amostra CSV p ver em excel
    df_massivo.head(500).to_csv(OUTPUT_CSV_VERIFICACAO, index=False)
except Exception as e:
    print(f"Erro no salvamento Parquet: {e}")
    # se fallhar por nao ter pyarrow salva CSV 
    print("Tentando salvar CSV direto (mais lento)...")
    df_massivo.to_csv(OUTPUT_PARQUET.replace(".parquet", ".csv"), index=False)
    print("Exportado CSV!")

print("\n--- RESUMO DA VOLUMETRIA ---")
print(df_massivo.info())
