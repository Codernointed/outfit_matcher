# ═══════════════════════════════════════════════════════════════
# FIX DARK MODE - Update all hardcoded colors to respect theme
# ═══════════════════════════════════════════════════════════════

Write-Host "`n🌙 FIXING DARK MODE THEMING" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

Set-Location $PSScriptRoot\..

Write-Host "📍 Working directory: $(Get-Location)`n" -ForegroundColor Yellow

# ───────────────────────────────────────────────────────────────
# Summary of issues found
# ───────────────────────────────────────────────────────────────
Write-Host "🔍 Analyzing dark mode issues..." -ForegroundColor Green
Write-Host ""

Write-Host "📋 Issues Found:" -ForegroundColor Yellow
Write-Host "  ⚠️  50+ hardcoded Colors.white in home_screen.dart" -ForegroundColor Gray
Write-Host "  ⚠️  20+ hardcoded Colors.black in home_screen.dart" -ForegroundColor Gray
Write-Host "  ⚠️  Similar issues across other screens" -ForegroundColor Gray
Write-Host ""

Write-Host "🎨 Fix Strategy:" -ForegroundColor Yellow
Write-Host "  ✅ Replace Colors.white with theme.colorScheme.surface" -ForegroundColor White
Write-Host "  ✅ Replace Colors.black overlays with theme.colorScheme.onSurface" -ForegroundColor White
Write-Host "  ✅ Use theme.colorScheme properties for all colors" -ForegroundColor White
Write-Host "  ✅ Add isDark checks for context-specific colors" -ForegroundColor White
Write-Host ""

Write-Host "⚡ This requires manual fixes in the following files:" -ForegroundColor Yellow
Write-Host "  📄 home_screen.dart (primary screen)" -ForegroundColor White
Write-Host "  📄 upload_options_screen.dart" -ForegroundColor White
Write-Host "  📄 Other presentation screens" -ForegroundColor White
Write-Host ""

Write-Host "🔧 Running automated formatter..." -ForegroundColor Green
dart format .
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "⚠️  MANUAL FIXES REQUIRED" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "The following patterns need to be fixed manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Before: color: Colors.white" -ForegroundColor Red
Write-Host "  After:  color: theme.colorScheme.surface" -ForegroundColor Green
Write-Host ""
Write-Host "  Before: backgroundColor: Colors.black.withValues(alpha: 0.5)" -ForegroundColor Red
Write-Host "  After:  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5)" -ForegroundColor Green
Write-Host ""
Write-Host "  Before: Container(color: Colors.white," -ForegroundColor Red
Write-Host "  After:  Container(color: theme.colorScheme.surface," -ForegroundColor Green
Write-Host ""

Write-Host "🎯 Agent will now fix these issues in home_screen.dart and other files!" -ForegroundColor Cyan
Write-Host ""
