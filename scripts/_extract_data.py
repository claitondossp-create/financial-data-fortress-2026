import pandas as pd
import os
import json

gold = r'c:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\data\03_gold'

fato = pd.read_csv(os.path.join(gold, 'fato_financeiro.csv'))
geo = pd.read_csv(os.path.join(gold, 'dim_geografia.csv'))
prod = pd.read_csv(os.path.join(gold, 'dim_produto.csv'))
seg = pd.read_csv(os.path.join(gold, 'dim_segmento.csv'))
tempo = pd.read_csv(os.path.join(gold, 'dim_tempo.csv'))

data = {}

# KPIs
data['receita_total'] = float(fato['receita_liquida'].sum())
data['lucro_total'] = float(fato['lucro'].sum())
data['margem_bruta'] = float(fato['lucro'].sum() / fato['receita_liquida'].sum() * 100)
data['unidades_vendidas'] = int(fato['unidades_vendidas'].sum())
data['cpv'] = float(fato['custo_produtos_vendidos'].sum())
data['ticket_medio'] = float(fato['receita_liquida'].sum() / fato['unidades_vendidas'].sum())

# Por Pais
m = fato.merge(geo, on='geografia_sk')
by_c = m.groupby('pais').agg({'receita_liquida':'sum','lucro':'sum'}).sort_values('receita_liquida', ascending=False).reset_index()
data['por_pais'] = by_c.to_dict('records')

# Por Segmento
m2 = fato.merge(seg, on='segmento_sk')
by_s = m2.groupby('nome_segmento').agg({'receita_liquida':'sum'}).sort_values('receita_liquida', ascending=False).reset_index()
data['por_segmento'] = by_s.to_dict('records')

# Por Produto
m3 = fato.merge(prod, on='produto_sk')
by_p = m3.groupby('nome_produto').agg({
    'receita_liquida':'sum',
    'lucro':'sum',
    'unidades_vendidas':'sum'
}).sort_values('receita_liquida', ascending=False).reset_index()
by_p['nome_produto'] = by_p['nome_produto'].str.strip()
by_p['margem'] = by_p['lucro'] / by_p['receita_liquida'] * 100
data['por_produto'] = by_p.to_dict('records')

# Por Mes/Ano
m4 = fato.merge(tempo[['tempo_sk','ano','mes']], on='tempo_sk')
by_m = m4.groupby(['ano','mes']).agg({'receita_liquida':'sum','lucro':'sum'}).reset_index().sort_values(['ano','mes'])
by_m['ano'] = by_m['ano'].astype(int)
by_m['mes'] = by_m['mes'].astype(int)
data['por_mes'] = by_m.to_dict('records')

print(json.dumps(data, indent=2, ensure_ascii=False))
