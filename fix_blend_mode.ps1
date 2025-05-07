$filePath = "c:\Users\Marco\Desktop\Flutter Dev\artistry_pro\lib\screens\canvas_screen.dart"
$content = Get-Content -Path $filePath -Raw
$content = $content -replace "onBlendModeChanged: \(mode\) \{\s+appState\.canvasEngine\.setLayerBlendMode\(", "onBlendModeChanged: (painting_models.CustomBlendMode mode) {`n                                         appState.canvasEngine.setLayerBlendMode("
Set-Content -Path $filePath -Value $content
Write-Host "Fixed BlendMode issue in canvas_screen.dart"
