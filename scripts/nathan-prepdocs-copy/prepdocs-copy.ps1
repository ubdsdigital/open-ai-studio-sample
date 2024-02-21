. ./scripts/loadenv.ps1

$venvPythonPath = "./.venv/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./.venv/bin/python"
}

Write-Host 'Running "prepdocs-copy.py"'
$cwd = (Get-Location)
Start-Process -FilePath $venvPythonPath -ArgumentList "./scripts/prepdocs-copy.py --searchservice $env:AZURE_SEARCH_SERVICE --index $env:AZURE_SEARCH_INDEX --formrecognizerservice $env:AZURE_FORMRECOGNIZER_SERVICE --tenantid $env:AZURE_TENANT_ID" -Wait -NoNewWindow
