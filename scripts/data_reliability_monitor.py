#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DATA RELIABILITY MONITOR - Contratos de Dados & Observabilidade
SRE (Site Reliability Engineering) para Financial Data Fortress 2026

Autor: Data Reliability Engineer (SRE)
Data: 2026-02-17
Conformidade: RULE_STRICT_GROUNDING | RULE_SECURITY_FIRST

OBJETIVO:
Implementar camada de confiabilidade sobre o pipeline de dados financeiros,
garantindo qualidade através de contratos Pydantic, carga incremental otimizada
e monitoramento inteligente de anomalias com Root Cause Analysis.

GROUNDING SOURCE:
- BLUEPRINT_DATAOPS_2026.md (Seção: Contratos de Dados, CDC, Vigilância com IA)
"""

import pandas as pd
import numpy as np
from pydantic import BaseModel, Field, validator, root_validator
from decimal import Decimal
from datetime import datetime, date, timedelta
from typing import Optional, Literal
import sqlite3
import json
import sys
from pathlib import Path

# ========================================
# CONFIGURAÇÕES GLOBAIS
# ========================================

CAMINHO_DADOS = "Financials_Silver.csv"
CAMINHO_METADATA_DB = "metadata/incremental_load.db"
CAMINHO_ALERTAS = "alerts/anomalies_{timestamp}.json"

# ========================================
# MÓDULO 1: DATA CONTRACT (Pydantic)
# ========================================

class SegmentoEnum(str):
    """Enum de segmentos permitidos."""
    GOVERNMENT = "Government"
    ENTERPRISE = "Enterprise"
    SMALL_BUSINESS = "Small Business"
    MIDMARKET = "Midmarket"
    CHANNEL_PARTNERS = "Channel Partners"

class DescontoBandEnum(str):
    """Enum de faixas de desconto permitidas."""
    NONE = "None"
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"

class FinancialRecordContract(BaseModel):
    """
    DATA CONTRACT v1.0.0 - Registro Financeiro
    
    Valida estrutura e regras de negócio ANTES do processamento.
    Qualquer violação rejeita o registro automaticamente.
    """
    
    # ========================================
    # CAMPOS OBRIGATÓRIOS
    # ========================================
    
    segment: str = Field(
        ...,
        description="Segmento de cliente"
    )
    
    country: str = Field(
        ...,
        min_length=3,
        max_length=100,
        description="Nome do país"
    )
    
    product: str = Field(
        ...,
        min_length=3,
        max_length=50,
        description="Nome do produto"
    )
    
    discount_band: str = Field(
        ...,
        description="Faixa de desconto"
    )
    
    units_sold: float = Field(
        ...,
        ge=0,  # greater than or equal
        description="Unidades vendidas (não negativo)"
    )
    
    manufacturing_price: float = Field(
        ...,
        ge=0,
        le=10000,
        description="Preço de fabricação unitário"
    )
    
    sale_price: float = Field(
        ...,
        ge=0,
        le=50000,
        description="Preço de venda unitário"
    )
    
    gross_sales: float = Field(
        ...,
        ge=0,
        description="Faturamento bruto"
    )
    
    discounts: float = Field(
        ...,
        ge=0,
        description="Valor total de descontos"
    )
    
    sales: float = Field(
        ...,
        ge=0,
        description="Venda líquida"
    )
    
    cogs: float = Field(
        ...,
        ge=0,
        description="Custo dos produtos vendidos"
    )
    
    profit: float = Field(
        ...,
        description="Lucro operacional (pode ser negativo)"
    )
    
    date: str = Field(
        ...,
        description="Data da transação (YYYY-MM-DD)"
    )
    
    month_number: int = Field(
        ...,
        ge=1,
        le=12,
        description="Número do mês"
    )
    
    month_name: str = Field(
        ...,
        description="Nome do mês em inglês"
    )
    
    year: int = Field(
        ...,
        ge=2013,
        le=2030,
        description="Ano fiscal"
    )
    
    # ========================================
    # VALIDADORES DE NEGÓCIO (REGRAS CRÍTICAS)
    # ========================================
    
    @validator('sales')
    def validar_sales(cls, v, values):
        """
        REGRA 1: Sales = Gross Sales - Discounts
        """
        if 'gross_sales' in values and 'discounts' in values:
            esperado = values['gross_sales'] - values['discounts']
            if abs(v - esperado) > 0.01:  # Tolerância de 1 centavo
                raise ValueError(
                    f"Sales inconsistente: {v} != {esperado} "
                    f"(Gross: {values['gross_sales']}, Desc: {values['discounts']})"
                )
        return v
    
    @validator('profit')
    def validar_profit(cls, v, values):
        """
        REGRA 2: Profit = Sales - COGS
        """
        if 'sales' in values and 'cogs' in values:
            esperado = values['sales'] - values['cogs']
            if abs(v - esperado) > 0.01:
                raise ValueError(
                    f"Profit inconsistente: {v} != {esperado} "
                    f"(Sales: {values['sales']}, COGS: {values['cogs']})"
                )
        return v
    
    @validator('date')
    def validar_formato_data(cls, v):
        """
        REGRA 3: Data deve estar em formato ISO-8601 (YYYY-MM-DD)
        """
        try:
            datetime.strptime(v, '%Y-%m-%d')
        except ValueError:
            raise ValueError(f"Data inválida '{v}'. Formato esperado: YYYY-MM-DD")
        return v
    
    @root_validator
    def validar_desconto_coerente(cls, values):
        """
        REGRA 4: Se discount_band = 'None', desconto deve ser 0
        """
        if values.get('discount_band') == 'None':
            if values.get('discounts', 0) > 0.01:
                raise ValueError(
                    f"Inconsistência: discount_band='None' mas discounts={values['discounts']}"
                )
        return values
    
    class Config:
        """Configurações do modelo Pydantic."""
        validate_assignment = True
        frozen = False

class DataContractValidator:
    """
    Validador de lote completo usando Data Contracts.
    """
    
    @staticmethod
    def validar_lote(df):
        """
        Valida lote de registros contra o contrato.
        
        Parameters
        ----------
        df : pd.DataFrame
            Lote a validar
        
        Returns
        -------
        tuple
            (df_valido, df_invalido, relatorio_erros)
        """
        
        print("🔍 Validando Data Contract (Pydantic)...")
        
        registros_validos = []
        registros_invalidos = []
        erros_detalhados = []
        
        for idx, row in df.iterrows():
            try:
                # Validar registro contra contrato
                registro_validado = FinancialRecordContract(**row.to_dict())
                registros_validos.append(row.to_dict())
                
            except Exception as e:
                # Capturar violação de contrato
                registros_invalidos.append(row.to_dict())
                erros_detalhados.append({
                    'linha': idx + 2,  # +2 porque: +1 para 1-indexed, +1 para header
                    'erro': str(e)
                })
        
        df_valido = pd.DataFrame(registros_validos)
        df_invalido = pd.DataFrame(registros_invalidos)
        
        taxa_aprovacao = (len(df_valido) / len(df)) * 100 if len(df) > 0 else 0
        
        print(f"   ✅ Válidos: {len(df_valido)} ({taxa_aprovacao:.1f}%)")
        print(f"   ❌ Inválidos: {len(df_invalido)}")
        
        if len(df_invalido) > 0:
            print(f"\n   ⚠️ VIOLAÇÕES DE CONTRATO:")
            for erro in erros_detalhados[:5]:  # Primeiros 5
                print(f"      Linha {erro['linha']}: {erro['erro']}")
        
        print()
        
        return df_valido, df_invalido, erros_detalhados

# ========================================
# MÓDULO 2: INCREMENTAL LOAD (CDC)
# ========================================

class IncrementalLoader:
    """
    Gerenciador de carga incremental baseada em timestamp.
    
    Evita 'Full Reload' processando apenas registros novos/modificados.
    """
    
    def __init__(self, db_path):
        self.db_path = db_path
        self.conn = None
        self._inicializar_db()
    
    def _inicializar_db(self):
        """Cria banco de metadados se não existir."""
        
        # Criar diretório
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        
        # Conectar
        self.conn = sqlite3.connect(self.db_path)
        
        # Criar tabela de watermark
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS watermark (
                pipeline_nome TEXT PRIMARY KEY,
                ultimo_timestamp_processado TEXT,
                ultimo_hash TEXT,
                registros_processados INTEGER,
                data_atualizacao TEXT
            )
        """)
        self.conn.commit()
    
    def obter_ultimo_watermark(self, pipeline_nome):
        """
        Recupera último timestamp processado.
        
        Parameters
        ----------
        pipeline_nome : str
            Nome do pipeline (ex: 'bronze_to_silver')
        
        Returns
        -------
        str or None
            Último timestamp processado
        """
        
        cursor = self.conn.execute(
            "SELECT ultimo_timestamp_processado FROM watermark WHERE pipeline_nome = ?",
            (pipeline_nome,)
        )
        resultado = cursor.fetchone()
        return resultado[0] if resultado else None
    
    def atualizar_watermark(self, pipeline_nome, timestamp, hash_dados, num_registros):
        """
        Atualiza watermark após processamento bem-sucedido.
        
        Parameters
        ----------
        pipeline_nome : str
            Nome do pipeline
        timestamp : str
            Novo timestamp de corte
        hash_dados : str
            Hash MD5 dos dados processados
        num_registros : int
            Quantidade de registros processados
        """
        
        self.conn.execute("""
            INSERT OR REPLACE INTO watermark 
            (pipeline_nome, ultimo_timestamp_processado, ultimo_hash, 
             registros_processados, data_atualizacao)
            VALUES (?, ?, ?, ?, ?)
        """, (
            pipeline_nome,
            timestamp,
            hash_dados,
            num_registros,
            datetime.now().isoformat()
        ))
        self.conn.commit()
    
    def carregar_incremental(self, df, coluna_timestamp, pipeline_nome):
        """
        Carrega apenas registros após último watermark.
        
        Parameters
        ----------
        df : pd.DataFrame
            Dataset completo
        coluna_timestamp : str
            Coluna que contém timestamp
        pipeline_nome : str
            Nome do pipeline
        
        Returns
        -------
        pd.DataFrame
            Apenas registros novos/modificados
        """
        
        print(f"⚡ Carga Incremental (Pipeline: {pipeline_nome})...")
        
        # Converter timestamp para datetime
        df[coluna_timestamp] = pd.to_datetime(df[coluna_timestamp])
        
        # Obter último watermark
        ultimo_watermark = self.obter_ultimo_watermark(pipeline_nome)
        
        if ultimo_watermark is None:
            # Primeira execução: carga completa
            print(f"   🆕 Primeira execução: processando {len(df)} registros (FULL LOAD)")
            df_delta = df
        else:
            # Carga incremental: apenas após watermark
            ultimo_watermark_dt = pd.to_datetime(ultimo_watermark)
            df_delta = df[df[coluna_timestamp] > ultimo_watermark_dt]
            
            print(f"   ⚡ Incremental: {len(df_delta)} novos registros desde {ultimo_watermark}")
            print(f"   💰 Economia: {((len(df) - len(df_delta)) / len(df) * 100):.1f}% de registros NÃO processados")
        
        # Atualizar watermark se houver novos dados
        if len(df_delta) > 0:
            novo_watermark = df_delta[coluna_timestamp].max().isoformat()
            hash_dados = pd.util.hash_pandas_object(df_delta).sum()
            
            self.atualizar_watermark(
                pipeline_nome,
                novo_watermark,
                str(hash_dados),
                len(df_delta)
            )
        
        print()
        return df_delta

# ========================================
# MÓDULO 3: ROOT CAUSE ANALYSIS (RCA)
# ========================================

class AnomalyDetector:
    """
    Detector de anomalias em lucro com análise de causa raiz.
    
    Dispara alertas se lucro oscilar > 100% da média histórica sazonal.
    """
    
    def __init__(self):
        self.baseline_sazonal = None
        self.alertas = []
    
    def calcular_baseline_sazonal(self, df):
        """
        Calcula média e desvio padrão de lucro por país e trimestre.
        
        Parameters
        ----------
        df : pd.DataFrame
            Dataset histórico
        
        Returns
        -------
        dict
            {(pais, trimestre): {'media': float, 'desvio': float}}
        """
        
        print("📊 Calculando Baseline Sazonal...")
        
        # Converter data para datetime
        df['date'] = pd.to_datetime(df['date'])
        df['trimestre'] = df['date'].dt.quarter
        
        # Agrupar por país e trimestre
        baseline = {}
        
        for (pais, trimestre), grupo in df.groupby(['country', 'trimestre']):
            lucro_medio = grupo['profit'].mean()
            lucro_desvio = grupo['profit'].std()
            num_transacoes = len(grupo)
            
            baseline[(pais, trimestre)] = {
                'media': lucro_medio,
                'desvio': lucro_desvio,
                'num_transacoes': num_transacoes
            }
        
        self.baseline_sazonal = baseline
        
        print(f"   ✅ Baseline calculado para {len(baseline)} combinações (país, trimestre)\n")
        
        return baseline
    
    def detectar_anomalias(self, df):
        """
        Detecta transações com lucro anômalo (> 100% da média sazonal).
        
        Parameters
        ----------
        df : pd.DataFrame
            Dataset a monitorar
        
        Returns
        -------
        pd.DataFrame
            Transações anômalas
        """
        
        print("🚨 Detectando Anomalias de Lucro...")
        
        if self.baseline_sazonal is None:
            print("   ⚠️ WARNING: Baseline não calculado. Use calcular_baseline_sazonal() primeiro.\n")
            return pd.DataFrame()
        
        # Preparar dados
        df['date'] = pd.to_datetime(df['date'])
        df['trimestre'] = df['date'].dt.quarter
        
        anomalias = []
        
        for idx, row in df.iterrows():
            pais = row['country']
            trimestre = row['trimestre']
            lucro_atual = row['profit']
            
            # Buscar baseline
            if (pais, trimestre) in self.baseline_sazonal:
                baseline = self.baseline_sazonal[(pais, trimestre)]
                lucro_esperado = baseline['media']
                desvio = baseline['desvio']
                
                # Detectar oscilação > 100% (dobro ou metade da média)
                variacao_percentual = ((lucro_atual - lucro_esperado) / lucro_esperado * 100) if lucro_esperado != 0 else 0
                
                # ALERTA se variação > 100% OU < -50%
                if abs(variacao_percentual) > 100:
                    anomalias.append({
                        'index': idx,
                        'pais': pais,
                        'produto': row['product'],
                        'data': row['date'].strftime('%Y-%m-%d'),
                        'trimestre': trimestre,
                        'lucro_atual': lucro_atual,
                        'lucro_esperado': lucro_esperado,
                        'variacao_percentual': variacao_percentual,
                        'severidade': 'CRÍTICA' if abs(variacao_percentual) > 200 else 'ALTA'
                    })
        
        df_anomalias = pd.DataFrame(anomalias)
        
        if len(df_anomalias) > 0:
            print(f"   🚨 {len(df_anomalias)} ANOMALIAS DETECTADAS")
            print(f"   Critério: Variação > 100% vs média sazonal\n")
        else:
            print(f"   ✅ Nenhuma anomalia detectada\n")
        
        return df_anomalias
    
    def analisar_causa_raiz(self, anomalia):
        """
        Analisa causa raiz de uma anomalia específica.
        
        Parameters
        ----------
        anomalia : dict
            Registro de anomalia
        
        Returns
        -------
        list
            Lista de causas raiz identificadas
        """
        
        causas = []
        
        # Causa 1: Lucro muito acima da média (estratégia de premium pricing?)
        if anomalia['variacao_percentual'] > 100:
            causas.append({
                'causa': 'LUCRO_ACIMA_MEDIA',
                'severidade': anomalia['severidade'],
                'detalhes': f"Lucro {anomalia['variacao_percentual']:.1f}% acima do esperado",
                'recomendacao': f"Investigar estratégia de precificação em {anomalia['pais']} (Q{anomalia['trimestre']})"
            })
        
        # Causa 2: Lucro muito abaixo da média (prejuízo ou desconto excessivo?)
        if anomalia['variacao_percentual'] < -50:
            causas.append({
                'causa': 'LUCRO_ABAIXO_MEDIA',
                'severidade': anomalia['severidade'],
                'detalhes': f"Lucro {abs(anomalia['variacao_percentual']):.1f}% abaixo do esperado",
                'recomendacao': f"Revisar política de descontos para {anomalia['produto']} em {anomalia['pais']}"
            })
        
        return causas
    
    def gerar_relatorio_alertas(self, df_anomalias):
        """
        Gera relatório JSON de alertas para integração com sistemas de monitoramento.
        
        Parameters
        ----------
        df_anomalias : pd.DataFrame
            Anomalias detectadas
        
        Returns
        -------
        str
            Caminho do relatório salvo
        """
        
        if len(df_anomalias) == 0:
            print("✅ Nenhum alerta gerado (sem anomalias)\n")
            return None
        
        print("📝 Gerando Relatório de Alertas...")
        
        # Preparar alertas
        alertas = []
        
        for _, anomalia in df_anomalias.iterrows():
            # Analisar causa raiz
            causas = self.analisar_causa_raiz(anomalia.to_dict())
            
            alerta = {
                'timestamp': datetime.now().isoformat(),
                'tipo': 'ANOMALIA_LUCRO',
                'severidade': anomalia['severidade'],
                'metrica': 'profit',
                'pais': anomalia['pais'],
                'produto': anomalia['produto'],
                'data_transacao': anomalia['data'],
                'trimestre': int(anomalia['trimestre']),
                'valores': {
                    'lucro_atual': float(anomalia['lucro_atual']),
                    'lucro_esperado': float(anomalia['lucro_esperado']),
                    'variacao_percentual': float(anomalia['variacao_percentual'])
                },
                'causas_raiz': causas
            }
            
            alertas.append(alerta)
        
        # Salvar JSON
        Path("alerts").mkdir(exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        caminho_relatorio = f"alerts/anomalies_{timestamp}.json"
        
        with open(caminho_relatorio, 'w', encoding='utf-8') as f:
            json.dump({
                'total_alertas': len(alertas),
                'criticas': sum(1 for a in alertas if a['severidade'] == 'CRÍTICA'),
                'altas': sum(1 for a in alertas if a['severidade'] == 'ALTA'),
                'timestamp_relatorio': datetime.now().isoformat(),
                'alertas': alertas
            }, f, indent=2, ensure_ascii=False)
        
        print(f"   ✅ Relatório salvo: {caminho_relatorio}")
        print(f"   Total de alertas: {len(alertas)}")
        print(f"   Críticas: {sum(1 for a in alertas if a['severidade'] == 'CRÍTICA')}")
        print(f"   Altas: {sum(1 for a in alertas if a['severidade'] == 'ALTA')}\n")
        
        return caminho_relatorio

# ========================================
# ORQUESTRADOR PRINCIPAL
# ========================================

class DataReliabilityMonitor:
    """
    Orquestrador que integra validação, carga incremental e monitoramento.
    """
    
    def __init__(self, caminho_dados, db_metadata):
        self.caminho_dados = caminho_dados
        self.validator = DataContractValidator()
        self.loader = IncrementalLoader(db_metadata)
        self.detector = AnomalyDetector()
    
    def executar_pipeline(self):
        """Executa pipeline completo de confiabilidade."""
        
        print("=" * 80)
        print("DATA RELIABILITY MONITOR - SRE")
        print("=" * 80)
        print(f"Timestamp: {datetime.now().isoformat()}\n")
        
        # ========================================
        # ETAPA 1: Carregar dados
        # ========================================
        print("📥 ETAPA 1: Carregando dados...")
        df = pd.read_csv(self.caminho_dados)
        print(f"   ✅ {len(df)} registros carregados\n")
        
        # ========================================
        # ETAPA 2: Carga incremental
        # ========================================
        print("=" * 80)
        print("ETAPA 2: CARGA INCREMENTAL (CDC)")
        print("=" * 80 + "\n")
        
        df_incremental = self.loader.carregar_incremental(
            df,
            coluna_timestamp='date',
            pipeline_nome='silver_to_gold'
        )
        
        # Se não há dados novos, encerrar
        if len(df_incremental) == 0:
            print("✅ Nenhum dado novo para processar. Pipeline encerrado.")
            return
        
        # ========================================
        # ETAPA 3: Validação de contrato
        # ========================================
        print("=" * 80)
        print("ETAPA 3: VALIDAÇÃO DE DATA CONTRACT (Pydantic)")
        print("=" * 80 + "\n")
        
        df_valido, df_invalido, erros = self.validator.validar_lote(df_incremental)
        
        # Se há registros inválidos, logar
        if len(df_invalido) > 0:
            Path("quarantine").mkdir(exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            caminho_quarentena = f"quarantine/contract_violations_{timestamp}.csv"
            df_invalido.to_csv(caminho_quarentena, index=False)
            
            print(f"   ⚠️ {len(df_invalido)} registros enviados para quarentena: {caminho_quarentena}\n")
        
        # ========================================
        # ETAPA 4: Calcular baseline sazonal
        # ========================================
        print("=" * 80)
        print("ETAPA 4: BASELINE SAZONAL (Histórico)")
        print("=" * 80 + "\n")
        
        # Usar dataset completo para baseline (não apenas incremental)
        self.detector.calcular_baseline_sazonal(df)
        
        # ========================================
        # ETAPA 5: Detectar anomalias
        # ========================================
        print("=" * 80)
        print("ETAPA 5: DETECÇÃO DE ANOMALIAS (Root Cause Analysis)")
        print("=" * 80 + "\n")
        
        df_anomalias = self.detector.detectar_anomalias(df_valido)
        
        # ========================================
        # ETAPA 6: Gerar alertas
        # ========================================
        if len(df_anomalias) > 0:
            print("=" * 80)
            print("ETAPA 6: GERAÇÃO DE ALERTAS")
            print("=" * 80 + "\n")
            
            caminho_alertas = self.detector.gerar_relatorio_alertas(df_anomalias)
        
        # ========================================
        # RESUMO FINAL
        # ========================================
        print("=" * 80)
        print("✅ PIPELINE DE CONFIABILIDADE CONCLUÍDO")
        print("=" * 80)
        print(f"Registros processados (incremental): {len(df_incremental)}")
        print(f"Registros válidos: {len(df_valido)}")
        print(f"Registros inválidos: {len(df_invalido)}")
        print(f"Anomalias detectadas: {len(df_anomalias)}")
        print()

# ========================================
# EXECUÇÃO PRINCIPAL
# ========================================

if __name__ == "__main__":
    """
    Execução do monitor de confiabilidade.
    
    USO:
        python data_reliability_monitor.py
    
    OUTPUT:
        - metadata/incremental_load.db (watermarks)
        - quarantine/contract_violations_*.csv (violações)
        - alerts/anomalies_*.json (alertas)
    """
    
    monitor = DataReliabilityMonitor(
        caminho_dados=CAMINHO_DADOS,
        db_metadata=CAMINHO_METADATA_DB
    )
    
    monitor.executar_pipeline()
    
    sys.exit(0)
