# Fix BOM encoding in all visual.json files
$basePath = "c:\Users\Claiton\Documents\GitHub\Conjunto de Dados Financeiros da Empresa\Financeiro.Report\definition\pages\d837769410cce3d61729\visuals"
$utf8NoBOM = New-Object System.Text.UTF8Encoding $false

Get-ChildItem -Path $basePath -Recurse -Filter "visual.json" | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName)
    [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBOM)
    Write-Host "Fixed BOM: $($_.Name) in $($_.Directory.Name)"
}

Write-Host "`nAll files fixed!" -ForegroundColor Green
