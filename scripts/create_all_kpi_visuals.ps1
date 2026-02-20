# === CRIAR TODOS OS VISUAIS DE KPI (6 PARES: CARD PRINCIPAL + SUBTITULO) ===
# Template EXATO baseado nos cards do usuario (Lucro Total + Receita YoY Texto)

$basePath = "c:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\Financeiro.Report\definition\pages\d837769410cce3d61729\visuals"

# Layout real (baseado nas posicoes existentes):
# Lucro Total usuario: x=490.19, y=125.35, h=59.1, w=219.1
# Subtitulo usuario:   x=499.36, y=184.46, h=68.3, w=180.4
# Area total: y=124 a y=252 (128px verticais)
# Pagina largura util: ~1170px (19 a 1189)
# 6 cards com ~150px cada + ~12px gap = 972px -> start x=19

$mainH = 59.108280254777071   # altura card principal (exata do usuario)
$mainW = 150.0                # largura (ajustada p/ caber 6)
$subH = 68.280254777070063   # altura subtitulo (exata do usuario)
$subW = 150.0
$y1 = 125.35031847133759   # y principal (exato do usuario)
$startX = 19.0
$gap = 12.0

# Cards que o usuario ja criou (Lucro Total)
$userMainId = "a358c400facdae4f2a95"
$userSubId = "6dc6832b88e5a35f9415"

# Cards antigos a remover
$oldCards = @("b87a96fb9737fa9ba7e9", "d007a3b61203aeb85da7")

# 6 KPIs
$kpis = @(
    @{ Name = "Receita Total"; Sub = "Receita YoY Texto"; Title = "Receita Total"; Units = "1000000D"; Prec = "1L"; MId = "aa11bb22cc33dd44ee01"; SId = "aa11bb22cc33dd44ef01"; Skip = $false },
    @{ Name = "Lucro Total"; Sub = "Lucro YoY Texto"; Title = "Lucro Total"; Units = "1000000D"; Prec = "3L"; MId = $userMainId; SId = $userSubId; Skip = $true },
    @{ Name = "Margem Bruta %"; Sub = "Margem Bruta Subtitulo"; Title = "Margem Bruta"; Units = "0D"; Prec = "1L"; MId = "aa11bb22cc33dd44ee03"; SId = "aa11bb22cc33dd44ef03"; Skip = $false },
    @{ Name = "Unidades Vendidas"; Sub = "Unidades Vendidas Subtitulo"; Title = "Unidades Vendidas"; Units = "1000000D"; Prec = "2L"; MId = "aa11bb22cc33dd44ee04"; SId = "aa11bb22cc33dd44ef04"; Skip = $false },
    @{ Name = "Custo Total (CPV)"; Sub = "Custo CPV Subtitulo"; Title = "Custo (CPV)"; Units = "1000000D"; Prec = "1L"; MId = "aa11bb22cc33dd44ee05"; SId = "aa11bb22cc33dd44ef05"; Skip = $false },
    @{ Name = "Ticket Medio"; Sub = "Ticket Medio Subtitulo"; Title = "Ticket Medio"; Units = "0D"; Prec = "2L"; MId = "aa11bb22cc33dd44ee06"; SId = "aa11bb22cc33dd44ef06"; Skip = $false }
)

function New-MainCardJson($name, $id, $x, $y, $z, $tab, $measure, $title, $units, $prec) {
    return @"
{
  "`$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.5.0/schema.json",
  "name": "$id",
  "position": {
    "x": $x,
    "y": $y,
    "z": $z,
    "height": $mainH,
    "width": $mainW,
    "tabOrder": $tab
  },
  "visual": {
    "visualType": "card",
    "query": {
      "queryState": {
        "Values": {
          "projections": [
            {
              "field": {
                "Measure": {
                  "Expression": {
                    "SourceRef": {
                      "Entity": "Medidas Insights"
                    }
                  },
                  "Property": "$measure"
                }
              },
              "queryRef": "Medidas Insights.$measure",
              "nativeQueryRef": "$measure"
            }
          ]
        }
      },
      "sortDefinition": {
        "sort": [
          {
            "field": {
              "Measure": {
                "Expression": {
                  "SourceRef": {
                    "Entity": "Medidas Insights"
                  }
                },
                "Property": "$measure"
              }
            },
            "direction": "Descending"
          }
        ],
        "isDefaultSort": true
      }
    },
    "objects": {
      "labels": [
        {
          "properties": {
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 4,
                      "Percent": 0
                    }
                  }
                }
              }
            },
            "labelPrecision": {
              "expr": {
                "Literal": {
                  "Value": "$prec"
                }
              }
            },
            "labelDisplayUnits": {
              "expr": {
                "Literal": {
                  "Value": "$units"
                }
              }
            },
            "fontSize": {
              "expr": {
                "Literal": {
                  "Value": "22D"
                }
              }
            },
            "bold": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            },
            "preserveWhitespace": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            }
          }
        }
      ],
      "categoryLabels": [
        {
          "properties": {
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 0,
                      "Percent": 0
                    }
                  }
                }
              }
            },
            "show": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            }
          }
        }
      ],
      "wordWrap": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            }
          }
        }
      ]
    },
    "visualContainerObjects": {
      "visualHeader": [
        {
          "properties": {
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "100D"
                }
              }
            },
            "background": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#252423'"
                    }
                  }
                }
              }
            },
            "border": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#252423'"
                    }
                  }
                }
              }
            },
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            }
          }
        }
      ],
      "background": [
        {
          "properties": {
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "100D"
                }
              }
            },
            "show": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            }
          }
        }
      ],
      "title": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "fontColor": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 2,
                      "Percent": 0
                    }
                  }
                }
              }
            },
            "titleWrap": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            },
            "text": {
              "expr": {
                "Literal": {
                  "Value": "'$title'"
                }
              }
            },
            "alignment": {
              "expr": {
                "Literal": {
                  "Value": "'center'"
                }
              }
            }
          }
        }
      ],
      "spacing": [
        {
          "properties": {
            "customizeSpacing": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "verticalSpacing": {
              "expr": {
                "Literal": {
                  "Value": "10D"
                }
              }
            },
            "spaceBelowTitle": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            }
          }
        }
      ],
      "subTitle": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            },
            "text": {
              "expr": {
                "Literal": {
                  "Value": "'$title'"
                }
              }
            },
            "fontSize": {
              "expr": {
                "Literal": {
                  "Value": "12D"
                }
              }
            },
            "alignment": {
              "expr": {
                "Literal": {
                  "Value": "'center'"
                }
              }
            },
            "fontColor": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 2,
                      "Percent": 0
                    }
                  }
                }
              }
            },
            "titleWrap": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            },
            "heading": {
              "expr": {
                "Literal": {
                  "Value": "'Normal'"
                }
              }
            }
          }
        }
      ],
      "divider": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            }
          }
        }
      ]
    },
    "drillFilterOtherVisuals": true
  },
  "filterConfig": {
    "filters": [
      {
        "name": "flt_main_$($id.Substring(0,20))",
        "field": {
          "Measure": {
            "Expression": {
              "SourceRef": {
                "Entity": "Medidas Insights"
              }
            },
            "Property": "$measure"
          }
        },
        "type": "Advanced"
      }
    ]
  }
}
"@
}

function New-SubCardJson($id, $x, $y, $z, $tab, $subMeasure) {
    return @"
{
  "`$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.5.0/schema.json",
  "name": "$id",
  "position": {
    "x": $x,
    "y": $y,
    "z": $z,
    "height": $subH,
    "width": $subW,
    "tabOrder": $tab
  },
  "visual": {
    "visualType": "card",
    "query": {
      "queryState": {
        "Values": {
          "projections": [
            {
              "field": {
                "Measure": {
                  "Expression": {
                    "SourceRef": {
                      "Entity": "Medidas Insights"
                    }
                  },
                  "Property": "$subMeasure"
                }
              },
              "queryRef": "Medidas Insights.$subMeasure",
              "nativeQueryRef": "$subMeasure"
            }
          ]
        }
      },
      "sortDefinition": {
        "isDefaultSort": true
      }
    },
    "objects": {
      "labels": [
        {
          "properties": {
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 4,
                      "Percent": 0
                    }
                  }
                }
              }
            },
            "labelPrecision": {
              "expr": {
                "Literal": {
                  "Value": "3L"
                }
              }
            },
            "labelDisplayUnits": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            },
            "fontSize": {
              "expr": {
                "Literal": {
                  "Value": "12D"
                }
              }
            },
            "bold": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            }
          }
        }
      ],
      "categoryLabels": [
        {
          "properties": {
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 0,
                      "Percent": 0
                    }
                  }
                }
              }
            },
            "show": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            }
          }
        }
      ]
    },
    "visualContainerObjects": {
      "visualHeader": [
        {
          "properties": {
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "100D"
                }
              }
            },
            "background": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#252423'"
                    }
                  }
                }
              }
            },
            "border": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#252423'"
                    }
                  }
                }
              }
            }
          }
        }
      ],
      "background": [
        {
          "properties": {
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "100D"
                }
              }
            }
          }
        }
      ],
      "title": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "fontColor": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 2,
                      "Percent": 0
                    }
                  }
                }
              }
            }
          }
        }
      ]
    },
    "drillFilterOtherVisuals": true
  },
  "filterConfig": {
    "filters": [
      {
        "name": "flt_sub_$($id.Substring(0,20))",
        "field": {
          "Measure": {
            "Expression": {
              "SourceRef": {
                "Entity": "Medidas Insights"
              }
            },
            "Property": "$subMeasure"
          }
        },
        "type": "Advanced"
      }
    ]
  }
}
"@
}

# 1. Remover cards antigos
foreach ($old in $oldCards) {
    $oldPath = Join-Path $basePath $old
    if (Test-Path $oldPath) {
        Remove-Item -Recurse -Force $oldPath
        Write-Host "Removido card antigo: $old" -ForegroundColor Yellow
    }
}

# 2. Criar novos cards
for ($i = 0; $i -lt $kpis.Count; $i++) {
    $kpi = $kpis[$i]
    $x = $startX + ($i * ($mainW + $gap))
    $y2 = $y1 + $mainH

    if ($kpi.Skip) {
        Write-Host "Pulando $($kpi.Title) (ja configurado pelo usuario)" -ForegroundColor Yellow
        # Reposicionar os cards do usuario
        $mainPath = Join-Path $basePath "$($kpi.MId)\visual.json"
        $subPath = Join-Path $basePath "$($kpi.SId)\visual.json"
        
        if (Test-Path $mainPath) {
            $json = Get-Content $mainPath -Raw | ConvertFrom-Json
            $json.position.x = $x
            $json.position.y = $y1
            $json.position.width = $mainW
            $json | ConvertTo-Json -Depth 20 | Set-Content $mainPath -Encoding UTF8
            Write-Host "  Reposicionado main: x=$x" -ForegroundColor Cyan
        }
        if (Test-Path $subPath) {
            $json = Get-Content $subPath -Raw | ConvertFrom-Json
            $json.position.x = $x
            $json.position.y = $y2
            $json.position.width = $subW
            $json | ConvertTo-Json -Depth 20 | Set-Content $subPath -Encoding UTF8
            Write-Host "  Reposicionado sub: x=$x" -ForegroundColor Cyan
        }
        continue
    }

    # Card principal
    $mainDir = Join-Path $basePath $kpi.MId
    if (-not (Test-Path $mainDir)) { New-Item -ItemType Directory -Path $mainDir -Force | Out-Null }
    $z = 2000 + ($i * 100)
    $mainJson = New-MainCardJson -name $kpi.MId -id $kpi.MId -x $x -y $y1 -z $z -tab ($i * 1000) -measure $kpi.Name -title $kpi.Title -units $kpi.Units -prec $kpi.Prec
    $mainJson | Set-Content -Path (Join-Path $mainDir "visual.json") -Encoding UTF8
    Write-Host "Criado: $($kpi.Title) (main) x=$x" -ForegroundColor Green

    # Card subtitulo
    $subDir = Join-Path $basePath $kpi.SId
    if (-not (Test-Path $subDir)) { New-Item -ItemType Directory -Path $subDir -Force | Out-Null }
    $subJson = New-SubCardJson -id $kpi.SId -x $x -y $y2 -z ($z + 1) -tab ($i * 1000 + 1) -subMeasure $kpi.Sub
    $subJson | Set-Content -Path (Join-Path $subDir "visual.json") -Encoding UTF8
    Write-Host "Criado: $($kpi.Sub) (sub) x=$x" -ForegroundColor Cyan
}

Write-Host "`nTodos os visuais criados com sucesso!" -ForegroundColor Green
Write-Host "Feche e reabra o .pbip para ver as mudancas." -ForegroundColor Yellow
