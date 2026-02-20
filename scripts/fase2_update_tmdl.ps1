# === FASE 2: DAX DEFENSIVO E FORMATACAO DINAMICA VIA TMDL ===

$tmdlPath = "C:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\Financeiro.SemanticModel\definition\tables\Medidas Insights.tmdl"
$content = Get-Content $tmdlPath -Raw

# 1. Aplicando FormatStringExpression dinâmico para Medidas Monetárias no TMDL
# O padrão no TMDL para Dynamic Format String é usar a propriedade formatStringDefinition

$monetaryMeasures = @(
    "Receita Total",
    "Lucro Total",
    "Custo Total (CPV)",
    "Receita Acumulada Ano",
    "Media Movel 3 Meses",
    "Lucro Acumulado Ano"
)

$dynamicFormatBlock = @"
		formatStringDefinition = 
				VAR _Valor = ABS(SELECTEDMEASURE())
				RETURN 
				SWITCH(
				    TRUE(),
				    _Valor >= 1000000000, """R$"" #,0.00,,,"" Bi""",
				    _Valor >= 1000000,    """R$"" #,0.00,,"" Mi""",
				    _Valor >= 1000,       """R$"" #,0.00,"" K""",
				    """R$"" #,0.00"
				)
"@

# Trocar as formatString fixas pelas dinâmicas
foreach ($m in $monetaryMeasures) {
    # Regex para achar a linha de format string atual da medida
    $regex = "(?ism)(^\s*measure '$m'.*?^\s*)formatString:.*?(?=^\s*displayFolder:)"
    if ($content -match $regex) {
        $replacement = "`$1$dynamicFormatBlock`n"
        $content = $content -replace $regex, $replacement
        Write-Host "FormatStringDefinition aplicado via TMDL para: $m" -ForegroundColor Green
    }
}

# 2. Refinando DAX da Margem Bruta
$regexGM = "(?ism)(^\s*measure 'Margem Bruta %' =).*?(?=^\s*formatString:)"
$content = $content -replace $regexGM, "`$1`n			DIVIDE([Lucro Total], [Receita Total], BLANK())`n"

# 3. Refinando DAX do Crescimento MoM
$regexMoM = "(?ism)(^\s*measure 'Crescimento MoM %' =).*?(?=^\s*formatString:)"
$daxMoM = @'

			VAR _Atual = [Receita Total]
			VAR _Anterior = CALCULATE([Receita Total], PREVIOUSMONTH(dim_tempo[data_completa]))
			RETURN
			    IF(
			        ISBLANK(_Anterior) || _Anterior = 0,
			        BLANK(),
			        DIVIDE(_Atual - _Anterior, _Anterior)
			    )

'@
$content = $content -replace $regexMoM, "`$1$daxMoM"

# Atualizar o TMDL
Set-Content $tmdlPath $content -Encoding UTF8
Write-Host "TMDL modificado diretamente com formatação dinâmica e DAX defensivo!" -ForegroundColor Cyan
