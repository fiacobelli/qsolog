# patch_main_cpp.ps1
# Run this once from your project root to add GPU compatibility flags to main.cpp
# Usage: .\patch_main_cpp.ps1

$mainCppPath = "windows\runner\main.cpp"

if (-not (Test-Path $mainCppPath)) {
    Write-Error "Could not find $mainCppPath — make sure you run this from your project root."
    exit 1
}

$content = Get-Content $mainCppPath -Raw

# Check if already patched
if ($content -contains "FLUTTER_ENGINE_SWITCH_0") {
    Write-Host "Already patched — nothing to do." -ForegroundColor Yellow
    exit 0
}

# The patch to insert — forces software rendering for GPU compatibility
$patch = @"
  // Force software rendering for compatibility with all GPU/display drivers.
  // Fixes blank window on computers with older or incompatible graphics drivers.
  ::SetEnvironmentVariable(L"FLUTTER_ENGINE_SWITCHES", L"2");
  ::SetEnvironmentVariable(L"FLUTTER_ENGINE_SWITCH_0", L"--disable-gpu");
  ::SetEnvironmentVariable(L"FLUTTER_ENGINE_SWITCH_1", L"--disable-gpu-compositing");

"@

# Find the opening brace of wWinMain and insert after it
$pattern = '(int APIENTRY wWinMain[^\{]*\{)'
$replacement = '$1' + "`n" + $patch

if ($content -match $pattern) {
    $patched = [regex]::Replace($content, $pattern, $replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    # Backup original
    Copy-Item $mainCppPath "$mainCppPath.bak"
    Write-Host "Backed up original to $mainCppPath.bak" -ForegroundColor Cyan
    
    # Write patched version
    Set-Content $mainCppPath $patched -Encoding UTF8
    Write-Host "Successfully patched $mainCppPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now rebuild with:" -ForegroundColor White
    Write-Host "  flutter build windows --release" -ForegroundColor Yellow
} else {
    Write-Error "Could not find wWinMain in $mainCppPath — file may have an unexpected structure."
    exit 1
}
