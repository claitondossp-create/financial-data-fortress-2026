#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VALIDAÇÃO DE QUALIDADE - CAMADA BRONZE
Great Expectations Script para Financial Data Fortress 2026

Autor: Senior Data Quality Engineer
Data: 2026-02-17
Conformidade: RULE_STRICT_GROUNDING | RULE_SECURITY_FIRST | RULE_INDIAN_NUM_SYSTEM

OBJETIVO:
Validar a qualidade do arquivo Financials.csv antes de ingressar na camada Silver.
Detectar anomalias críticas que comprometem a integridade dos dados.

GROUNDING SOURCE:
- RELATORIO_AUDITORIA_BRONZE.md (Seção: Perfilamento Analítico)
- Financials.csv (701 linhas, 16 colunas)
"""

import great_expectations as gx
from great_expectations.core import ExpectationSuite, ExpectationConfiguration
from great_expectations.dataset import PandasDataset
import pandas as pd
import re
import sys
from datetime import datetime
import json

# ========================================
# CONFIGURAÇÕES GLOBAIS
# ========================================

CAMINHO_CSV = "data/01_bronze/Financials.csv"
CAMINHO_QUARENTENA = "outputs/quarantine/bronze_failed_{timestamp}.csv"

# 16 Colunas obrigatórias conforme documentação
COLUNAS_OBRIGATORIAS = [
    "Segment", "Country", "Product", "Discount Band",
    "Units Sold", "Manufacturing Price", "Sale Price",
    "Gross Sales", "Discounts", " Sales", "COGS", "Profit",
    "Date", "Month Number", "Month Name", "Year"
]

# Colunas monetárias que podem conter Lakhs/Crores
COLUNAS_MONETARIAS = [
    "Manufacturing Price", "Sale Price", "Gross Sales",
    "Discounts", " Sales", "COGS", "Profit"
]

# ========================================
# EXPECTATIONS CUSTOMIZADAS
# ========================================

class CustomFinancialExpectations:
    """
    Expectations customizadas para detecção de anomalias financeiras.
    
    Baseado em RELATORIO_AUDITORIA_BRONZE.md - Seção 3.1 (Anomalias Críticas).
    """
    
    @staticmethod
    def expect_no_indian_number_notation(df, column):
        """
        EXPECTATION CUSTOMIZADA 1: Detectar sistema numérico indiano (Lakhs/Crores).
        
        Padrão Lakhs: 5,29,550 (vírgula a cada 2 dígitos após os 3 primeiros)
        Padrão Crores: 71,50,000
        
        Regex: r'\\d{1,3}(,\\d{2})+' 
        
        Mitiga "caracteres invisíveis": Espaços antes/depois da vírgula também são detectados.
        
        Returns
        -------
        dict
            {
                'success': bool,
                'result': {
                    'unexpected_count': int,
                    'unexpected_values': list
                }
            }
        """
        
        # Converter para string para análise regex
        valores_str = df[column].astype(str)
        
        # Regex para detectar Lakhs/Crores
        # Exemplo: "5,29,550" ou " 5,29,550 " (com espaços)
        padrao_indiano = r'\d{1,3}(,\d{2})+'
        
        # Detectar valores suspeitos
        mascara_invalidos = valores_str.str.contains(
            padrao_indiano, 
            regex=True, 
            na=False
        )
        
        valores_invalidos = df[mascara_invalidos][column].tolist()
        count_invalidos = len(valores_invalidos)
        
        return {
            'success': count_invalidos == 0,
            'result': {
                'unexpected_count': count_invalidos,
                'unexpected_values': valores_invalidos[:10],  # Primeiros 10
                'unexpected_percent': (count_invalidos / len(df)) * 100
            }
        }
    
    @staticmethod
    def expect_no_dollar_dash_notation(df, column):
        """
        EXPECTATION CUSTOMIZADA 2: Detectar notação "$-" para zero.
        
        Problema: "$-" é usado no CSV para representar $0.00
        
        Mitiga "caracteres invisíveis": Também detecta "$ -", " $- ", etc.
        
        Returns
        -------
        dict
            {
                'success': bool,
                'result': {
                    'unexpected_count': int,
                    'unexpected_values': list
                }
            }
        """
        
        valores_str = df[column].astype(str)
        
        # Regex para detectar "$-" com possíveis espaços invisíveis
        # Exemplos: "$-", "$ -", " $- ", "$  -"
        padrao_dollar_dash = r'\$\s*-'
        
        mascara_invalidos = valores_str.str.contains(
            padrao_dollar_dash, 
            regex=True, 
            na=False
        )
        
        valores_invalidos = df[mascara_invalidos][column].tolist()
        count_invalidos = len(valores_invalidos)
        
        return {
            'success': count_invalidos == 0,
            'result': {
                'unexpected_count': count_invalidos,
                'unexpected_values': valores_invalidos[:10],
                'unexpected_percent': (count_invalidos / len(df)) * 100
            }
        }
    
    @staticmethod
    def expect_no_parentheses_for_negative(df, column):
        """
        EXPECTATION CUSTOMIZADA 3: Detectar parênteses para números negativos.
        
        Problema: Formato contábil $(4,533.75) em vez de -4533.75
        
        Mitiga "caracteres invisíveis": Detecta espaços antes/dentro dos parênteses.
        
        Returns
        -------
        dict
            {
                'success': bool,
                'result': {
                    'unexpected_count': int,
                    'unexpected_values': list
                }
            }
        """
        
        valores_str = df[column].astype(str)
        
        # Regex para detectar parênteses com números
        # Exemplos: "$(4,533.75)", " $(4,533.75) ", "$( 4,533.75)"
        padrao_parenteses = r'\$?\s*\(\s*[\d,\.]+\s*\)'
        
        mascara_invalidos = valores_str.str.contains(
            padrao_parenteses, 
            regex=True, 
            na=False
        )
        
        valores_invalidos = df[mascara_invalidos][column].tolist()
        count_invalidos = len(valores_invalidos)
        
        return {
            'success': count_invalidos == 0,
            'result': {
                'unexpected_count': count_invalidos,
                'unexpected_values': valores_invalidos[:10],
                'unexpected_percent': (count_invalidos / len(df)) * 100
            }
        }
    
    @staticmethod
    def expect_no_invisible_characters(df, column):
        """
        EXPECTATION CUSTOMIZADA 4: Detectar caracteres invisíveis.
        
        Caracteres invisíveis comuns:
        - Zero-width space (U+200B)
        - Non-breaking space (U+00A0)
        - Tab (\t)
        - Carriage return (\r)
        - Múltiplos espaços consecutivos
        
        Mitiga "caracteres invisíveis" citados na fonte.
        
        Returns
        -------
        dict
            {
                'success': bool,
                'result': {
                    'unexpected_count': int,
                    'unexpected_values': list,
                    'invisible_chars_found': dict
                }
            }
        """
        
        valores_str = df[column].astype(str)
        
        # Padrões de caracteres invisíveis
        padroes_invisiveis = {
            'zero_width_space': r'\u200B',
            'non_breaking_space': r'\u00A0',
            'tab': r'\t',
            'carriage_return': r'\r',
            'multiple_spaces': r'  +',  # 2+ espaços consecutivos
            'leading_whitespace': r'^\s+',
            'trailing_whitespace': r'\s+$'
        }
        
        chars_encontrados = {}
        mascara_invalidos = pd.Series([False] * len(df))
        
        for nome_padrao, regex in padroes_invisiveis.items():
            mascara_atual = valores_str.str.contains(regex, regex=True, na=False)
            count_atual = mascara_atual.sum()
            
            if count_atual > 0:
                chars_encontrados[nome_padrao] = count_atual
                mascara_invalidos |= mascara_atual
        
        valores_invalidos = df[mascara_invalidos][column].tolist()
        count_invalidos = len(valores_invalidos)
        
        return {
            'success': count_invalidos == 0,
            'result': {
                'unexpected_count': count_invalidos,
                'unexpected_values': valores_invalidos[:10],
                'unexpected_percent': (count_invalidos / len(df)) * 100,
                'invisible_chars_found': chars_encontrados
            }
        }

# ========================================
# VALIDADOR PRINCIPAL
# ========================================

class BronzeQualityValidator:
    """
    Validador de qualidade para camada Bronze usando Great Expectations.
    """
    
    def __init__(self, caminho_csv):
        self.caminho_csv = caminho_csv
        self.df = None
        self.context = gx.get_context()
        self.custom_expectations = CustomFinancialExpectations()
        self.resultados = {
            'validacao_bem_sucedida': False,
            'timestamp': datetime.now().isoformat(),
            'total_linhas': 0,
            'total_colunas': 0,
            'expectations_passadas': 0,
            'expectations_falhadas': 0,
            'detalhes_falhas': []
        }
    
    def carregar_dados(self):
        """Carrega CSV como PandasDataset do Great Expectations."""
        print("=" * 80)
        print("BRONZE QUALITY VALIDATOR - Great Expectations")
        print("=" * 80)
        print(f"Arquivo: {self.caminho_csv}")
        print(f"Timestamp: {self.resultados['timestamp']}\n")
        
        try:
            # Carregar como DataFrame Pandas
            self.df = pd.read_csv(self.caminho_csv, encoding='utf-8')
            
            # Converter para PandasDataset (Great Expectations)
            self.df = PandasDataset(self.df)
            
            self.resultados['total_linhas'] = len(self.df)
            self.resultados['total_colunas'] = len(self.df.columns)
            
            print(f"✅ Dados carregados: {self.resultados['total_linhas']} linhas, {self.resultados['total_colunas']} colunas\n")
            
        except Exception as e:
            print(f"❌ ERRO ao carregar CSV: {e}")
            sys.exit(1)
    
    def validar_schema(self):
        """
        VALIDAÇÃO 1: Verificar se possui as 16 colunas obrigatórias.
        """
        print("🔍 VALIDAÇÃO 1: Schema (16 colunas obrigatórias)")
        print("-" * 80)
        
        colunas_atuais = set(self.df.columns)
        colunas_esperadas = set(COLUNAS_OBRIGATORIAS)
        
        faltantes = colunas_esperadas - colunas_atuais
        extras = colunas_atuais - colunas_esperadas
        
        if faltantes or extras:
            print(f"❌ FALHA: Schema inválido")
            
            if faltantes:
                print(f"   Colunas faltantes: {faltantes}")
                self.resultados['detalhes_falhas'].append({
                    'validacao': 'schema',
                    'tipo': 'colunas_faltantes',
                    'valores': list(faltantes)
                })
            
            if extras:
                print(f"   Colunas extras: {extras}")
                self.resultados['detalhes_falhas'].append({
                    'validacao': 'schema',
                    'tipo': 'colunas_extras',
                    'valores': list(extras)
                })
            
            self.resultados['expectations_falhadas'] += 1
            print()
            return False
        
        else:
            print(f"✅ PASSOU: Todas as 16 colunas presentes\n")
            self.resultados['expectations_passadas'] += 1
            return True
    
    def validar_lakhs_crores(self):
        """
        VALIDAÇÃO 2: Detectar notação indiana (Lakhs/Crores) em colunas monetárias.
        """
        print("🔍 VALIDAÇÃO 2: Notação Indiana (Lakhs/Crores)")
        print("-" * 80)
        
        falhas_encontradas = False
        
        for coluna in COLUNAS_MONETARIAS:
            if coluna in self.df.columns:
                resultado = self.custom_expectations.expect_no_indian_number_notation(
                    self.df, coluna
                )
                
                if not resultado['success']:
                    falhas_encontradas = True
                    print(f"❌ FALHA: {coluna}")
                    print(f"   Registros com Lakhs/Crores: {resultado['result']['unexpected_count']}")
                    print(f"   Exemplos: {resultado['result']['unexpected_values'][:3]}\n")
                    
                    self.resultados['detalhes_falhas'].append({
                        'validacao': 'lakhs_crores',
                        'coluna': coluna,
                        'count': resultado['result']['unexpected_count'],
                        'percent': resultado['result']['unexpected_percent'],
                        'exemplos': resultado['result']['unexpected_values'][:5]
                    })
        
        if falhas_encontradas:
            self.resultados['expectations_falhadas'] += 1
            return False
        else:
            print("✅ PASSOU: Nenhuma notação indiana detectada\n")
            self.resultados['expectations_passadas'] += 1
            return True
    
    def validar_dollar_dash(self):
        """
        VALIDAÇÃO 3: Detectar notação "$-" na coluna Discounts.
        """
        print("🔍 VALIDAÇÃO 3: Notação '$-' em Discounts")
        print("-" * 80)
        
        if "Discounts" in self.df.columns:
            resultado = self.custom_expectations.expect_no_dollar_dash_notation(
                self.df, "Discounts"
            )
            
            if not resultado['success']:
                print(f"❌ FALHA: Discounts")
                print(f"   Registros com '$-': {resultado['result']['unexpected_count']}")
                print(f"   Exemplos: {resultado['result']['unexpected_values'][:3]}\n")
                
                self.resultados['detalhes_falhas'].append({
                    'validacao': 'dollar_dash',
                    'coluna': 'Discounts',
                    'count': resultado['result']['unexpected_count'],
                    'percent': resultado['result']['unexpected_percent'],
                    'exemplos': resultado['result']['unexpected_values'][:5]
                })
                
                self.resultados['expectations_falhadas'] += 1
                return False
            
            else:
                print("✅ PASSOU: Nenhum '$-' detectado\n")
                self.resultados['expectations_passadas'] += 1
                return True
        
        return True
    
    def validar_parenteses(self):
        """
        VALIDAÇÃO 4: Detectar parênteses para negativos na coluna Profit.
        """
        print("🔍 VALIDAÇÃO 4: Parênteses para Negativos em Profit")
        print("-" * 80)
        
        if "Profit" in self.df.columns:
            resultado = self.custom_expectations.expect_no_parentheses_for_negative(
                self.df, "Profit"
            )
            
            if not resultado['success']:
                print(f"❌ FALHA: Profit")
                print(f"   Registros com parênteses: {resultado['result']['unexpected_count']}")
                print(f"   Exemplos: {resultado['result']['unexpected_values'][:3]}\n")
                
                self.resultados['detalhes_falhas'].append({
                    'validacao': 'parenteses_negativos',
                    'coluna': 'Profit',
                    'count': resultado['result']['unexpected_count'],
                    'percent': resultado['result']['unexpected_percent'],
                    'exemplos': resultado['result']['unexpected_values'][:5]
                })
                
                self.resultados['expectations_falhadas'] += 1
                return False
            
            else:
                print("✅ PASSOU: Nenhum parêntese detectado\n")
                self.resultados['expectations_passadas'] += 1
                return True
        
        return True
    
    def validar_caracteres_invisiveis(self):
        """
        VALIDAÇÃO 5: Detectar caracteres invisíveis em TODAS as colunas.
        """
        print("🔍 VALIDAÇÃO 5: Caracteres Invisíveis (Zero-width, tabs, etc.)")
        print("-" * 80)
        
        falhas_encontradas = False
        
        for coluna in self.df.columns:
            resultado = self.custom_expectations.expect_no_invisible_characters(
                self.df, coluna
            )
            
            if not resultado['success']:
                falhas_encontradas = True
                print(f"❌ FALHA: {coluna}")
                print(f"   Registros com chars invisíveis: {resultado['result']['unexpected_count']}")
                print(f"   Tipos detectados: {resultado['result']['invisible_chars_found']}")
                print(f"   Exemplos: {resultado['result']['unexpected_values'][:2]}\n")
                
                self.resultados['detalhes_falhas'].append({
                    'validacao': 'caracteres_invisiveis',
                    'coluna': coluna,
                    'count': resultado['result']['unexpected_count'],
                    'tipos': resultado['result']['invisible_chars_found'],
                    'exemplos': resultado['result']['unexpected_values'][:3]
                })
        
        if falhas_encontradas:
            self.resultados['expectations_falhadas'] += 1
            return False
        else:
            print("✅ PASSOU: Nenhum caractere invisível detectado\n")
            self.resultados['expectations_passadas'] += 1
            return True
    
    def executar_quarentena(self):
        """
        PROTOCOLO DE QUARENTENA:
        Se qualquer validação falhar, desviar lote para quarentena.
        """
        print("=" * 80)
        print("🔒 PROTOCOLO DE QUARENTENA ATIVADO")
        print("=" * 80)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        caminho_quarentena = CAMINHO_QUARENTENA.format(timestamp=timestamp)
        
        # Criar diretório de quarentena se não existir
        import os
        os.makedirs('outputs/quarantine', exist_ok=True)
        
        # Salvar lote falhado
        self.df.to_csv(caminho_quarentena, index=False)
        
        # Salvar relatório JSON
        caminho_relatorio = f"outputs/quarantine/report_{timestamp}.json"
        with open(caminho_relatorio, 'w', encoding='utf-8') as f:
            json.dump(self.resultados, f, indent=2, ensure_ascii=False)
        
        print(f"❌ LOTE DESVIADO PARA QUARENTENA")
        print(f"   Arquivo: {caminho_quarentena}")
        print(f"   Relatório: {caminho_relatorio}")
        print(f"   Expectations falhadas: {self.resultados['expectations_falhadas']}")
        print(f"   Expectations passadas: {self.resultados['expectations_passadas']}\n")
        
        print("⚠️ AÇÃO NECESSÁRIA: Corrigir anomalias antes de prosseguir para Silver\n")
        
        return caminho_quarentena, caminho_relatorio
    
    def gerar_relatorio_sucesso(self):
        """Gera relatório de sucesso se todas as validações passarem."""
        print("=" * 80)
        print("✅ VALIDAÇÃO CONCLUÍDA COM SUCESSO")
        print("=" * 80)
        print(f"Expectations passadas: {self.resultados['expectations_passadas']}")
        print(f"Expectations falhadas: {self.resultados['expectations_falhadas']}")
        print(f"\n🚀 Lote aprovado para ingestão na Camada Silver\n")
        
        # Salvar relatório de sucesso
        caminho_sucesso = f"outputs/reports/validation_success_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        import os
        os.makedirs('outputs/reports', exist_ok=True)
        
        with open(caminho_sucesso, 'w', encoding='utf-8') as f:
            json.dump(self.resultados, f, indent=2, ensure_ascii=False)
        
        print(f"📊 Relatório salvo: {caminho_sucesso}\n")
        
        return caminho_sucesso
    
    def validar_tudo(self):
        """Executa todas as validações em sequência."""
        
        self.carregar_dados()
        
        # Executar cada validação
        validacoes = [
            self.validar_schema(),
            self.validar_lakhs_crores(),
            self.validar_dollar_dash(),
            self.validar_parenteses(),
            self.validar_caracteres_invisiveis()
        ]
        
        # Verificar se todas passaram
        todas_passaram = all(validacoes)
        
        self.resultados['validacao_bem_sucedida'] = todas_passaram
        
        if not todas_passaram:
            caminho_quarentena, caminho_relatorio = self.executar_quarentena()
            return False, caminho_quarentena
        else:
            caminho_relatorio = self.gerar_relatorio_sucesso()
            return True, caminho_relatorio

# ========================================
# EXECUÇÃO PRINCIPAL
# ========================================

if __name__ == "__main__":
    """
    Execução do validador de qualidade Bronze.
    
    USO:
        python validate_bronze_quality.py
    
    RETORNO:
        0: Sucesso (todas validações passaram)
        1: Falha (lote em quarentena)
    """
    
    validador = BronzeQualityValidator(CAMINHO_CSV)
    sucesso, caminho_output = validador.validar_tudo()
    
    # Exit code para integração com pipelines (Airflow, etc.)
    sys.exit(0 if sucesso else 1)
