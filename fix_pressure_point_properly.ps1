$filePath = "c:\Users\Marco\Desktop\Flutter Dev\artistry_pro\lib\screens\canvas_screen.dart"
$content = Get-Content -Path $filePath -Raw
$content = $content -replace "painting_models\.PressurePoint\(point: ([^,]+), pressure: ([^)]+)\)", "painting_models.PressurePoint(`$1, pressure: `$2)"
Set-Content -Path $filePath -Value $content
Write-Host "Fixed PressurePoint constructor calls in canvas_screen.dart with correct parameter format"
