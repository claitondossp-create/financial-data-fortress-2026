"""
Traduz os headers das tabelas Gold para PT-BR completo.
Também renomeia os arquivos de tabela para nomes em português, se necessário.
"""
import os
import pandas as pd

GOLD_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "03_gold")

# ================================================================
# MAPEAMENTO DE COLUNAS — inglês/misto → PT-BR
# ================================================================
COLUMN_MAP = {
    # dim_desconto
    "desconto_sk":       "desconto_sk",
    "faixa_desconto":    "faixa_desconto",
    "percentual_min":    "percentual_minimo",
    "percentual_max":    "percentual_maximo",

    # dim_geografia
    "geografia_sk":      "geografia_sk",
    "pais":              "pais",
    "continente":        "continente",
    "regiao":            "regiao",

    # dim_produto
    "produto_sk":        "produto_sk",
    "produto_nome":      "nome_produto",
    "preco_fabricacao":   "preco_fabricacao",
    "categoria_preco":   "categoria_preco",

    # dim_segmento
    "segmento_sk":       "segmento_sk",
    "segmento_nome":     "nome_segmento",
    "potencial_volume":  "potencial_volume",

    # dim_tempo
    "tempo_sk":            "tempo_sk",
    "data_completa":       "data_completa",
    "ano":                 "ano",
    "mes":                 "mes",
    "dia":                 "dia",
    "dia_semana":          "dia_semana",
    "trimestre":           "trimestre",
    "trimestre_fiscal":    "trimestre_fiscal",
    "eh_fim_mes":          "fim_de_mes",
    "eh_fim_trimestre":    "fim_de_trimestre",
    "eh_fim_ano":          "fim_de_ano",
    "eh_feriado_bancario": "feriado_bancario",

    # fato_financeiro
    "fato_financeiro_sk":  "fato_financeiro_sk",
    "produto_sk":          "produto_sk",
    "geografia_sk":        "geografia_sk",
    "segmento_sk":         "segmento_sk",
    "desconto_sk":         "desconto_sk",
    "tempo_sk":            "tempo_sk",
    "unidades_vendidas":   "unidades_vendidas",
    "venda_liquida":       "receita_liquida",
    "custo_bens_vendidos": "custo_produtos_vendidos",
    "lucro":               "lucro",
}

FILES = [
    "dim_desconto.csv",
    "dim_geografia.csv",
    "dim_produto.csv",
    "dim_segmento.csv",
    "dim_tempo.csv",
    "fato_financeiro.csv",
]


def translate_file(filename: str) -> dict:
    """Traduz os headers de um CSV e retorna as colunas renomeadas."""
    filepath = os.path.join(GOLD_DIR, filename)
    df = pd.read_csv(filepath)

    old_cols = list(df.columns)
    rename_map = {}
    for col in old_cols:
        col_clean = col.strip()
        if col_clean in COLUMN_MAP:
            rename_map[col] = COLUMN_MAP[col_clean]
        else:
            rename_map[col] = col_clean  # manter como está

    df.rename(columns=rename_map, inplace=True)
    df.to_csv(filepath, index=False)

    changes = {k: v for k, v in rename_map.items() if k.strip() != v}
    return changes


def main():
    print("=" * 60)
    print(" TRADUZINDO TABELAS GOLD PARA PT-BR")
    print("=" * 60)

    total_changes = 0

    for fname in FILES:
        print(f"\n📄 {fname}")
        changes = translate_file(fname)
        if changes:
            for old, new in changes.items():
                print(f"   {old.strip():30s} → {new}")
            total_changes += len(changes)
        else:
            print("   (sem alterações)")

    print(f"\n{'=' * 60}")
    print(f" TOTAL: {total_changes} colunas renomeadas")
    print(f"{'=' * 60}")

    # Mostrar headers finais
    print("\n📋 HEADERS FINAIS:")
    for fname in FILES:
        filepath = os.path.join(GOLD_DIR, fname)
        header = open(filepath, encoding="utf-8").readline().strip()
        print(f"\n  {fname}:")
        for col in header.split(","):
            print(f"    • {col}")


if __name__ == "__main__":
    main()
