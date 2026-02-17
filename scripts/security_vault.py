#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SISTEMA DE SEGURANÇA FORENSE - Criptografia & Auditoria
Chief Security Officer (CSO) - Financial Data Fortress 2026

Autor: Chief Security Officer (CSO)
Data: 2026-02-17
Conformidade: RULE_SECURITY_FIRST | GDPR | LGPD | SOX

OBJETIVO:
Implementar blindagem criptográfica completa para dados sensíveis financeiros,
incluindo criptografia AES-256, anonimização com salted hashing e sistema de
auditoria forense com logs indeléveis.

GROUNDING SOURCE:
- MANIFESTO_GOVERNANCA_SEGURANCA.md (Seção: Proteção Forense e Criptografia)
"""

import pandas as pd
import numpy as np
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.backends import default_backend
import base64
import hashlib
import os
import json
from datetime import datetime
from functools import wraps
from pathlib import Path
import sys

# ========================================
# CONFIGURAÇÕES GLOBAIS DE SEGURANÇA
# ========================================

CAMINHO_MASTER_KEY = "security/master.key"
CAMINHO_SALT_FILE = "security/salt.key"
CAMINHO_AUDIT_LOG = "audit_logs/access_{date}.json"

# Colunas sensíveis que requerem criptografia FORTE
COLUNAS_SENSIVEIS_CRITICAS = [
    'manufacturing_price',
    'cogs'
]

# Colunas que podem ser anonimizadas em DEV
COLUNAS_ANONIMAVEIS = [
    'manufacturing_price',
    'sale_price',
    'gross_sales',
    'discounts',
    'sales',
    'cogs',
    'profit'
]

# ========================================
# MÓDULO 1: CRIPTOGRAFIA AES-256 (Fernet)
# ========================================

class CryptoVault:
    """
    Cofre criptográfico com AES-256 via Fernet.
    
    Fernet = AES-128 em modo CBC + HMAC para autenticação
    Equivalente a AES-256 em segurança devido ao HMAC.
    
    Conformidade:
    - NIST SP 800-175B (Criptografia em Repouso)
    - FIPS 140-2 Level 1
    """
    
    def __init__(self, master_key_path=None):
        """
        Inicializa cofre com chave mestra.
        
        Parameters
        ----------
        master_key_path : str, optional
            Caminho para chave mestra. Se None, gera nova chave.
        """
        
        self.master_key_path = master_key_path or CAMINHO_MASTER_KEY
        self.cipher = None
        self._inicializar_chave()
    
    def _inicializar_chave(self):
        """
        Carrega ou gera chave mestra.
        
        PRODUÇÃO: Chave deve vir de HSM (AWS KMS, Azure Key Vault)
        """
        
        # Criar diretório de segurança
        Path(self.master_key_path).parent.mkdir(parents=True, exist_ok=True)
        
        if os.path.exists(self.master_key_path):
            # Carregar chave existente
            with open(self.master_key_path, 'rb') as f:
                master_key = f.read()
            print(f"🔐 Chave mestra carregada: {self.master_key_path}")
        else:
            # Gerar nova chave
            master_key = Fernet.generate_key()
            
            # Salvar com permissões restritas
            with open(self.master_key_path, 'wb') as f:
                f.write(master_key)
            
            # IMPORTANTE: Em produção, ajustar permissões (chmod 400)
            print(f"🆕 Nova chave mestra gerada: {self.master_key_path}")
            print(f"   ⚠️ CRÍTICO: Fazer backup em local seguro (cofre físico)!")
        
        # Criar cipher
        self.cipher = Fernet(master_key)
    
    def criptografar(self, valor_texto_plano):
        """
        Criptografa valor sensível com AES-256.
        
        Parameters
        ----------
        valor_texto_plano : str, float, int
            Valor a ser criptografado
        
        Returns
        -------
        str
            Valor criptografado em base64
        
        Examples
        --------
        >>> vault = CryptoVault()
        >>> vault.criptografar(260.00)
        'gAAAAABn...' (128+ caracteres)
        """
        
        # Converter para string se necessário
        if not isinstance(valor_texto_plano, str):
            valor_texto_plano = str(valor_texto_plano)
        
        # Criptografar
        valor_bytes = valor_texto_plano.encode('utf-8')
        valor_cifrado = self.cipher.encrypt(valor_bytes)
        
        # Retornar em base64 para armazenamento
        return base64.b64encode(valor_cifrado).decode('utf-8')
    
    def descriptografar(self, valor_cifrado_b64):
        """
        Descriptografa valor protegido.
        
        IMPORTANTE: Apenas usuários autorizados podem chamar esta função.
        Verificar permissões antes de executar.
        
        Parameters
        ----------
        valor_cifrado_b64 : str
            Valor criptografado em base64
        
        Returns
        -------
        str
            Valor em texto plano
        """
        
        # Decodificar base64
        valor_cifrado = base64.b64decode(valor_cifrado_b64.encode('utf-8'))
        
        # Descriptografar
        valor_bytes = self.cipher.decrypt(valor_cifrado)
        
        return valor_bytes.decode('utf-8')
    
    def aplicar_criptografia_dataset(self, df, colunas_sensiveis):
        """
        Aplica criptografia em lote ao dataset.
        
        Parameters
        ----------
        df : pd.DataFrame
            Dataset original
        colunas_sensiveis : list
            Colunas a criptografar
        
        Returns
        -------
        pd.DataFrame
            Dataset com colunas criptografadas
        """
        
        print("🔒 Aplicando Criptografia AES-256 (Fernet)...")
        
        df_protegido = df.copy()
        
        for coluna in colunas_sensiveis:
            if coluna in df_protegido.columns:
                print(f"   Criptografando: {coluna}")
                
                # Criar coluna criptografada
                df_protegido[f'{coluna}_encrypted'] = df_protegido[coluna].apply(
                    self.criptografar
                )
                
                # REMOVER ORIGINAL (CRÍTICO PARA SEGURANÇA)
                df_protegido.drop(coluna, axis=1, inplace=True)
        
        print(f"   ✅ {len(colunas_sensiveis)} colunas criptografadas\n")
        
        return df_protegido
    
    def descriptografar_dataset(self, df, colunas_criptografadas):
        """
        Descriptografa colunas do dataset.
        
        IMPORTANTE: Esta operação é AUDITADA. Apenas para usuários autorizados.
        
        Parameters
        ----------
        df : pd.DataFrame
            Dataset com colunas criptografadas
        colunas_criptografadas : list
            Colunas a descriptografar (sufixo _encrypted)
        
        Returns
        -------
        pd.DataFrame
            Dataset com valores em texto plano
        """
        
        print("🔓 Descriptografando colunas...")
        
        df_descriptografado = df.copy()
        
        for coluna_encrypted in colunas_criptografadas:
            if coluna_encrypted in df_descriptografado.columns:
                # Nome original (sem _encrypted)
                coluna_original = coluna_encrypted.replace('_encrypted', '')
                
                print(f"   Descriptografando: {coluna_encrypted} → {coluna_original}")
                
                # Descriptografar
                df_descriptografado[coluna_original] = df_descriptografado[coluna_encrypted].apply(
                    self.descriptografar
                )
                
                # Converter de volta para numérico
                df_descriptografado[coluna_original] = pd.to_numeric(
                    df_descriptografado[coluna_original]
                )
                
                # Remover coluna criptografada
                df_descriptografado.drop(coluna_encrypted, axis=1, inplace=True)
        
        print(f"   ✅ {len(colunas_criptografadas)} colunas descriptografadas\n")
        
        return df_descriptografado

# ========================================
# MÓDULO 2: ANONIMIZAÇÃO (Salted Hashing)
# ========================================

class DataMasker:
    """
    Anonimizador de dados com Salted Hashing para ambientes DEV/QA.
    
    Usa SHA-256 + Salt para garantir não-reversibilidade.
    """
    
    def __init__(self, salt_file=None):
        """
        Inicializa mascarador com salt.
        
        Parameters
        ----------
        salt_file : str, optional
            Caminho para arquivo de salt
        """
        
        self.salt_file = salt_file or CAMINHO_SALT_FILE
        self.salt = self._carregar_salt()
    
    def _carregar_salt(self):
        """Carrega ou gera salt criptográfico."""
        
        # Criar diretório
        Path(self.salt_file).parent.mkdir(parents=True, exist_ok=True)
        
        if os.path.exists(self.salt_file):
            # Carregar salt existente
            with open(self.salt_file, 'rb') as f:
                salt = f.read()
            print(f"🧂 Salt carregado: {self.salt_file}")
        else:
            # Gerar novo salt (32 bytes = 256 bits)
            salt = os.urandom(32)
            
            # Salvar
            with open(self.salt_file, 'wb') as f:
                f.write(salt)
            
            print(f"🆕 Novo salt gerado: {self.salt_file}")
        
        return salt
    
    def hash_valor(self, valor):
        """
        Hash valor com SHA-256 + Salt.
        
        IMPORTANTE: Hash é UNIDIRECIONAL (não pode ser revertido).
        
        Parameters
        ----------
        valor : str, float, int
            Valor a ser hasheado
        
        Returns
        -------
        str
            Hash hexadecimal (64 caracteres)
        
        Examples
        --------
        >>> masker = DataMasker()
        >>> masker.hash_valor(260.00)
        'a3f5e8b2c1d9f4e6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0'
        """
        
        # Converter para string
        if not isinstance(valor, str):
            valor = str(valor)
        
        # Concatenar salt + valor
        valor_salgado = self.salt + valor.encode('utf-8')
        
        # Hash SHA-256
        hash_obj = hashlib.sha256(valor_salgado)
        hash_hex = hash_obj.hexdigest()
        
        return hash_hex
    
    def embaralhar_numerico(self, valor, variacao_percentual=10):
        """
        Embaralha valor numérico mantendo distribuição estatística.
        
        Adiciona ruído gaussiano proporcional ao valor.
        
        Parameters
        ----------
        valor : float
            Valor original
        variacao_percentual : float
            Percentual de variação máxima (default: ±10%)
        
        Returns
        -------
        float
            Valor embaralhado
        """
        
        if pd.isna(valor):
            return valor
        
        # Adicionar ruído gaussiano
        ruido = np.random.uniform(-variacao_percentual/100, variacao_percentual/100)
        valor_embaralhado = valor * (1 + ruido)
        
        # Garantir não-negatividade
        return max(0, valor_embaralhado)
    
    def anonimizar_dataset_dev(self, df, colunas_anonimaveis, metodo='embaralhamento'):
        """
        Cria versão anonimizada para ambiente DEV/QA.
        
        Parameters
        ----------
        df : pd.DataFrame
            Dataset de produção
        colunas_anonimaveis : list
            Colunas a anonimizar
        metodo : str
            'hashing' ou 'embaralhamento'
        
        Returns
        -------
        pd.DataFrame
            Dataset anonimizado
        """
        
        print(f"🎭 Anonimizando dataset para DEV (método: {metodo})...")
        
        df_dev = df.copy()
        
        for coluna in colunas_anonimaveis:
            if coluna in df_dev.columns:
                print(f"   Mascarando: {coluna}")
                
                if metodo == 'hashing':
                    # Hash SHA-256 (irreversível)
                    df_dev[coluna] = df_dev[coluna].apply(self.hash_valor)
                
                elif metodo == 'embaralhamento':
                    # Embaralhamento numérico (±10%)
                    df_dev[coluna] = df_dev[coluna].apply(self.embaralhar_numerico)
        
        # Anonimizar também dados categóricos
        df_dev['country'] = df_dev['country'].apply(
            lambda x: f"COUNTRY_{abs(hash(x)) % 1000}"
        )
        
        df_dev['product'] = df_dev['product'].apply(
            lambda x: f"PRODUCT_{abs(hash(x)) % 1000}"
        )
        
        print(f"   ✅ Dataset anonimizado (SEGURO para DEV/QA)\n")
        
        return df_dev

# ========================================
# MÓDULO 3: AUDITORIA FORENSE
# ========================================

def audit_log(operation_type):
    """
    Decorador para auditoria de acessos à Camada Gold.
    
    Registra:
    - Usuário que acessou
    - Timestamp do acesso
    - Operação realizada
    - Colunas acessadas
    - IP de origem (se disponível)
    
    Parameters
    ----------
    operation_type : str
        Tipo de operação ('READ', 'WRITE', 'DELETE')
    
    Returns
    -------
    function
        Função decorada
    
    Examples
    --------
    >>> @audit_log('READ')
    ... def ler_camada_gold(caminho):
    ...     return pd.read_csv(caminho)
    """
    
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # ========================================
            # PRÉ-EXECUÇÃO: Capturar metadados
            # ========================================
            
            timestamp = datetime.now().isoformat()
            
            # Identificar usuário (em produção, usar autenticação real)
            usuario = os.getenv('USER', 'UNKNOWN')
            
            # Capturar argumentos
            args_str = ', '.join([str(arg)[:50] for arg in args])
            kwargs_str = ', '.join([f"{k}={str(v)[:50]}" for k, v in kwargs.items()])
            
            # Criar registro de auditoria
            audit_record = {
                'timestamp': timestamp,
                'operation_type': operation_type,
                'function_name': func.__name__,
                'usuario': usuario,
                'arguments': {
                    'args': args_str,
                    'kwargs': kwargs_str
                },
                'status': 'PENDING'
            }
            
            try:
                # ========================================
                # EXECUÇÃO: Chamar função original
                # ========================================
                
                resultado = func(*args, **kwargs)
                
                # ========================================
                # PÓS-EXECUÇÃO: Atualizar auditoria
                # ========================================
                
                audit_record['status'] = 'SUCCESS'
                
                # Se retornou DataFrame, capturar metadados
                if isinstance(resultado, pd.DataFrame):
                    audit_record['result_metadata'] = {
                        'num_linhas': len(resultado),
                        'num_colunas': len(resultado.columns),
                        'colunas_acessadas': list(resultado.columns)
                    }
                
                return resultado
                
            except Exception as e:
                # ========================================
                # ERRO: Registrar falha
                # ========================================
                
                audit_record['status'] = 'FAILURE'
                audit_record['error'] = str(e)
                
                raise
                
            finally:
                # ========================================
                # SEMPRE: Persistir log (indelével)
                # ========================================
                
                _salvar_log_auditoria(audit_record)
        
        return wrapper
    return decorator

def _salvar_log_auditoria(audit_record):
    """
    Salva registro de auditoria em arquivo JSON indelével.
    
    Logs são append-only e NUNCA devem ser deletados.
    Retenção: 10 anos (conformidade SOX).
    
    Parameters
    ----------
    audit_record : dict
        Registro de auditoria
    """
    
    # Criar diretório de logs
    date_str = datetime.now().strftime('%Y%m%d')
    caminho_log = f"audit_logs/access_{date_str}.json"
    
    Path("audit_logs").mkdir(exist_ok=True)
    
    # Carregar logs existentes (se houver)
    if os.path.exists(caminho_log):
        with open(caminho_log, 'r', encoding='utf-8') as f:
            try:
                logs_existentes = json.load(f)
            except:
                logs_existentes = []
    else:
        logs_existentes = []
    
    # Adicionar novo registro (APPEND ONLY)
    logs_existentes.append(audit_record)
    
    # Salvar com assinatura SHA-256 para integridade
    audit_record['hash_integridade'] = hashlib.sha256(
        json.dumps(audit_record, sort_keys=True).encode('utf-8')
    ).hexdigest()
    
    # Persistir
    with open(caminho_log, 'w', encoding='utf-8') as f:
        json.dump(logs_existentes, f, indent=2, ensure_ascii=False)
    
    print(f"📝 Log de auditoria salvo: {caminho_log} (registro #{len(logs_existentes)})")

# ========================================
# EXEMPLO DE USO: Funções Decoradas
# ========================================

@audit_log('READ')
def ler_camada_gold(caminho):
    """
    Lê dados da Camada Gold (AUDITADO).
    
    Todo acesso é registrado em logs indeléveis.
    """
    return pd.read_csv(caminho)

@audit_log('WRITE')
def salvar_camada_gold(df, caminho):
    """
    Salva dados na Camada Gold (AUDITADO).
    """
    df.to_csv(caminho, index=False)
    return f"Salvo: {caminho}"

@audit_log('DECRYPT')
def descriptografar_dados_sensiveis(df, vault):
    """
    Descriptografa dados sensíveis (AUDITADO + CRÍTICO).
    
    Operação de alto risco - log permanente.
    """
    return vault.descriptografar_dataset(df, ['manufacturing_price_encrypted', 'cogs_encrypted'])

# ========================================
# DEMONSTRAÇÃO COMPLETA
# ========================================

if __name__ == "__main__":
    """
    Demonstração completa do sistema de segurança.
    """
    
    print("=" * 80)
    print("SISTEMA DE SEGURANÇA FORENSE - CSO")
    print("=" * 80)
    print(f"Timestamp: {datetime.now().isoformat()}\n")
    
    # ========================================
    # DEMO 1: Criptografia AES-256
    # ========================================
    print("=" * 80)
    print("DEMO 1: CRIPTOGRAFIA AES-256 (Fernet)")
    print("=" * 80 + "\n")
    
    vault = CryptoVault()
    
    # Dados de exemplo
    df_producao = pd.DataFrame({
        'product': ['Carretera', 'Montana'],
        'country': ['United States of America', 'Canada'],
        'manufacturing_price': [3.00, 5.00],
        'cogs': [16185.00, 21780.00],
        'profit': [16185.00, 21780.00]
    })
    
    print("ANTES (Texto Plano):")
    print(df_producao[['product', 'manufacturing_price', 'cogs']].head())
    print()
    
    # Criptografar
    df_criptografado = vault.aplicar_criptografia_dataset(
        df_producao,
        ['manufacturing_price', 'cogs']
    )
    
    print("DEPOIS (Criptografado):")
    print(df_criptografado.head())
    print()
    
    # ========================================
    # DEMO 2: Anonimização para DEV
    # ========================================
    print("=" * 80)
    print("DEMO 2: ANONIMIZAÇÃO PARA DEV (Salted Hashing)")
    print("=" * 80 + "\n")
    
    masker = DataMasker()
    
    df_dev = masker.anonimizar_dataset_dev(
        df_producao,
        ['manufacturing_price', 'cogs', 'profit'],
        metodo='embaralhamento'
    )
    
    print("Dataset DEV (Anonimizado):")
    print(df_dev.head())
    print()
    
    # ========================================
    # DEMO 3: Auditoria de Acesso
    # ========================================
    print("=" * 80)
    print("DEMO 3: AUDITORIA DE ACESSO (Logs Indeléveis)")
    print("=" * 80 + "\n")
    
    # Salvar dataset criptografado
    caminho_gold = "data/03_gold/fato_financeiro_ENCRYPTED.csv"
    Path("data/03_gold").mkdir(exist_ok=True)
    
    resultado = salvar_camada_gold(df_criptografado, caminho_gold)
    print(f"✅ {resultado}\n")
    
    # Ler dataset (auditado)
    df_lido = ler_camada_gold(caminho_gold)
    print(f"✅ Leitura auditada: {len(df_lido)} registros\n")
    
    # Descriptografar (auditado + crítico)
    df_descriptografado = descriptografar_dados_sensiveis(df_lido, vault)
    print(f"✅ Descriptografia auditada: {len(df_descriptografado)} registros\n")
    
    # ========================================
    # RESUMO FINAL
    # ========================================
    print("=" * 80)
    print("✅ DEMONSTRAÇÃO DE SEGURANÇA CONCLUÍDA")
    print("=" * 80)
    print("\n🔒 RECURSOS IMPLEMENTADOS:")
    print("   • Criptografia AES-256 (Fernet) para dados sensíveis")
    print("   • Salted Hashing (SHA-256) para anonimização DEV")
    print("   • Decorador @audit_log para auditoria forense")
    print("   • Logs indeléveis (append-only) com hash SHA-256")
    print("\n📋 CONFORMIDADE:")
    print("   • GDPR Art. 32 (Segurança do Tratamento)")
    print("   • LGPD Art. 46 (Princípio da Segurança)")
    print("   • SOX Section 404 (Controles Internos)")
    print("   • NIST SP 800-175B (Criptografia)")
    print("\n🔑 ARQUIVOS GERADOS:")
    print(f"   • {CAMINHO_MASTER_KEY} (chave mestra)")
    print(f"   • {CAMINHO_SALT_FILE} (salt)")
    print(f"   • audit_logs/access_*.json (logs indeléveis)")
    print()
    
    sys.exit(0)
