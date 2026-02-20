$ws = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces" -Directory | Select-Object -First 1
$port = [System.IO.File]::ReadAllText((Join-Path $ws.FullName "Data\msmdsrv.port.txt"), [System.Text.Encoding]::Unicode).Trim() -replace '\0', ''

Import-Module SqlServer
@("Microsoft.AnalysisServices.Core.dll", "Microsoft.AnalysisServices.Tabular.dll") | ForEach-Object { [System.Reflection.Assembly]::LoadFrom("$((Get-Module SqlServer).ModuleBase)\$_") | Out-Null }

$srv = New-Object Microsoft.AnalysisServices.Tabular.Server
$srv.Connect("Data Source=localhost:$port")
$measures = @()
foreach ($m in $srv.Databases[0].Model.Tables["Medidas Insights"].Measures) {
    if ($m.FormatString -match "Mi" -or $m.FormatString -match "R\$") {
        $measures += [PSCustomObject]@{
            Name         = $m.Name
            FormatString = $m.FormatString
        }
    }
}
$measures | ConvertTo-Json
