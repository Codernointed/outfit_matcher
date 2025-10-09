#!/usr/bin/env pwsh
# Fix Deprecated Flutter/Dart Code Script
# Efficiently fixes withOpacity and other deprecated patterns

param(
    [string]$ProjectPath = ".",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = $Reset)
    Write-Host "$Color$Message$Reset"
}

function Test-FlutterProject {
    if (-not (Test-Path "$ProjectPath/pubspec.yaml")) {
        Write-ColorOutput "❌ Error: Not a Flutter project. pubspec.yaml not found." $Red
        exit 1
    }
    Write-ColorOutput "✅ Flutter project detected" $Green
}

function Backup-Files {
    $BackupDir = "$ProjectPath/.deprecated_fix_backup"
    if (Test-Path $BackupDir) {
        Remove-Item $BackupDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
    
    Get-ChildItem -Path "$ProjectPath/lib" -Recurse -Filter "*.dart" | ForEach-Object {
        $RelativePath = $_.FullName.Substring($ProjectPath.Length + 1)
        $BackupPath = Join-Path $BackupDir $RelativePath
        $BackupDirPath = Split-Path $BackupPath -Parent
        if (-not (Test-Path $BackupDirPath)) {
            New-Item -ItemType Directory -Path $BackupDirPath -Force | Out-Null
        }
        Copy-Item $_.FullName $BackupPath
    }
    Write-ColorOutput "📁 Backup created at: $BackupDir" $Blue
}

function Fix-WithOpacity {
    param([string]$FilePath)
    
    $Content = Get-Content $FilePath -Raw
    $OriginalContent = $Content
    $Changes = 0
    
    # Fix withOpacity patterns
    $Patterns = @{
        # Color.withOpacity() -> Color.withValues(alpha: ...)
        '(\w+)\.withOpacity\(([^)]+)\)' = '$1.withValues(alpha: $2)'
        
        # Colors.black.withOpacity() -> Colors.black.withValues(alpha: ...)
        'Colors\.black\.withOpacity\(([^)]+)\)' = 'Colors.black.withValues(alpha: $1)'
        'Colors\.white\.withOpacity\(([^)]+)\)' = 'Colors.white.withValues(alpha: $1)'
        
        # Theme colors with withOpacity
        'theme\.colorScheme\.(\w+)\.withOpacity\(([^)]+)\)' = 'theme.colorScheme.$1.withValues(alpha: $2)'
        
        # MaterialStateProperty.withOpacity
        'MaterialStateProperty\.all\(([^)]+)\.withOpacity\(([^)]+)\)\)' = 'MaterialStateProperty.all($1.withValues(alpha: $2))'
    }
    
    foreach ($Pattern in $Patterns.GetEnumerator()) {
        $NewContent = $Content -replace $Pattern.Key, $Pattern.Value
        if ($NewContent -ne $Content) {
            $Matches = [regex]::Matches($Content, $Pattern.Key)
            $Changes += $Matches.Count
            $Content = $NewContent
        }
    }
    
    if ($Content -ne $OriginalContent) {
        if ($DryRun) {
            Write-ColorOutput "🔍 Would fix $Changes withOpacity patterns in: $FilePath" $Yellow
        } else {
            Set-Content -Path $FilePath -Value $Content -NoNewline
            Write-ColorOutput "✅ Fixed $Changes withOpacity patterns in: $FilePath" $Green
        }
        return $Changes
    }
    return 0
}

function Fix-DeprecatedWidgets {
    param([string]$FilePath)
    
    $Content = Get-Content $FilePath -Raw
    $OriginalContent = $Content
    $Changes = 0
    
    # Fix deprecated widget patterns
    $Patterns = @{
        # FlatButton -> TextButton
        'FlatButton\(' = 'TextButton('
        'FlatButton\.icon\(' = 'TextButton.icon('
        
        # RaisedButton -> ElevatedButton
        'RaisedButton\(' = 'ElevatedButton('
        'RaisedButton\.icon\(' = 'ElevatedButton.icon('
        
        # OutlineButton -> OutlinedButton
        'OutlineButton\(' = 'OutlinedButton('
        'OutlineButton\.icon\(' = 'OutlinedButton.icon('
        
        # ButtonTheme -> ButtonStyle
        'ButtonTheme\.of\(context\)' = 'ButtonStyle.of(context)'
        
        # Deprecated constructors
        'TextStyle\(fontSize: ([^,]+), fontWeight: FontWeight\.w([0-9]+)\)' = 'TextStyle(fontSize: $1, fontWeight: FontWeight.w$2)'
        
        # Deprecated EdgeInsets
        'EdgeInsets\.fromLTRB\(' = 'EdgeInsets.fromLTRB('
        
        # Deprecated BoxDecoration
        'BoxDecoration\(border: Border\.all\(color: ([^,]+), width: ([^)]+)\)\)' = 'BoxDecoration(border: Border.all(color: $1, width: $2))'
    }
    
    foreach ($Pattern in $Patterns.GetEnumerator()) {
        $NewContent = $Content -replace $Pattern.Key, $Pattern.Value
        if ($NewContent -ne $Content) {
            $Matches = [regex]::Matches($Content, $Pattern.Key)
            $Changes += $Matches.Count
            $Content = $NewContent
        }
    }
    
    if ($Content -ne $OriginalContent) {
        if ($DryRun) {
            Write-ColorOutput "🔍 Would fix $Changes deprecated widgets in: $FilePath" $Yellow
        } else {
            Set-Content -Path $FilePath -Value $Content -NoNewline
            Write-ColorOutput "✅ Fixed $Changes deprecated widgets in: $FilePath" $Green
        }
        return $Changes
    }
    return 0
}

function Fix-DeprecatedMethods {
    param([string]$FilePath)
    
    $Content = Get-Content $FilePath -Raw
    $OriginalContent = $Content
    $Changes = 0
    
    # Fix deprecated method patterns
    $Patterns = @{
        # Deprecated Navigator methods
        'Navigator\.of\(context\)\.pushReplacementNamed\(' = 'Navigator.of(context).pushReplacement('
        'Navigator\.of\(context\)\.pushNamedAndRemoveUntil\(' = 'Navigator.of(context).pushAndRemoveUntil('
        
        # Deprecated MediaQuery
        'MediaQuery\.of\(context\)\.size\.width' = 'MediaQuery.sizeOf(context).width'
        'MediaQuery\.of\(context\)\.size\.height' = 'MediaQuery.sizeOf(context).height'
        'MediaQuery\.of\(context\)\.padding' = 'MediaQuery.paddingOf(context)'
        
        # Deprecated Scaffold.of
        'Scaffold\.of\(context\)\.showSnackBar\(' = 'ScaffoldMessenger.of(context).showSnackBar('
        
        # Deprecated Theme.of
        'Theme\.of\(context\)\.textTheme' = 'Theme.of(context).textTheme'
        'Theme\.of\(context\)\.colorScheme' = 'Theme.of(context).colorScheme'
        
        # Deprecated Image.network
        'Image\.network\(' = 'Image.network('
        
        # Deprecated ListView.builder with shrinkWrap
        'ListView\.builder\(shrinkWrap: true,' = 'ListView.builder(shrinkWrap: true,'
    }
    
    foreach ($Pattern in $Patterns.GetEnumerator()) {
        $NewContent = $Content -replace $Pattern.Key, $Pattern.Value
        if ($NewContent -ne $Content) {
            $Matches = [regex]::Matches($Content, $Pattern.Key)
            $Changes += $Matches.Count
            $Content = $NewContent
        }
    }
    
    if ($Content -ne $OriginalContent) {
        if ($DryRun) {
            Write-ColorOutput "🔍 Would fix $Changes deprecated methods in: $FilePath" $Yellow
        } else {
            Set-Content -Path $FilePath -Value $Content -NoNewline
        }
        return $Changes
    }
    return 0
}

function Fix-DeprecatedImports {
    param([string]$FilePath)
    
    $Content = Get-Content $FilePath -Raw
    $OriginalContent = $Content
    $Changes = 0
    
    # Fix deprecated import patterns
    $Patterns = @{
        # Remove unused imports (basic cleanup)
        'import ''package:flutter/material\.dart'';[\r\n]+import ''package:flutter/material\.dart'';' = 'import ''package:flutter/material.dart'';'
        
        # Fix relative imports
        'import ''\.\./\.\./core/' = 'import ''package:vestiq/core/'
        'import ''\.\./\.\./features/' = 'import ''package:vestiq/features/'
    }
    
    foreach ($Pattern in $Patterns.GetEnumerator()) {
        $NewContent = $Content -replace $Pattern.Key, $Pattern.Value
        if ($NewContent -ne $Content) {
            $Matches = [regex]::Matches($Content, $Pattern.Key)
            $Changes += $Matches.Count
            $Content = $NewContent
        }
    }
    
    if ($Content -ne $OriginalContent) {
        if ($DryRun) {
            Write-ColorOutput "🔍 Would fix $Changes deprecated imports in: $FilePath" $Yellow
        } else {
            Set-Content -Path $FilePath -Value $Content -NoNewline
        }
        return $Changes
    }
    return 0
}

function Fix-DeprecatedTheme {
    param([string]$FilePath)
    
    $Content = Get-Content $FilePath -Raw
    $OriginalContent = $Content
    $Changes = 0
    
    # Fix deprecated theme patterns
    $Patterns = @{
        # Deprecated ThemeData properties
        'primaryColor:' = 'colorScheme: ColorScheme.fromSeed(seedColor:'
        'accentColor:' = 'colorScheme: ColorScheme.fromSeed(seedColor:'
        
        # Deprecated color properties
        'Colors\.grey\[100\]' = 'Colors.grey.shade100'
        'Colors\.grey\[200\]' = 'Colors.grey.shade200'
        'Colors\.grey\[300\]' = 'Colors.grey.shade300'
        'Colors\.grey\[400\]' = 'Colors.grey.shade400'
        'Colors\.grey\[500\]' = 'Colors.grey.shade500'
        'Colors\.grey\[600\]' = 'Colors.grey.shade600'
        'Colors\.grey\[700\]' = 'Colors.grey.shade700'
        'Colors\.grey\[800\]' = 'Colors.grey.shade800'
        'Colors\.grey\[900\]' = 'Colors.grey.shade900'
    }
    
    foreach ($Pattern in $Patterns.GetEnumerator()) {
        $NewContent = $Content -replace $Pattern.Key, $Pattern.Value
        if ($NewContent -ne $Content) {
            $Matches = [regex]::Matches($Content, $Pattern.Key)
            $Changes += $Matches.Count
            $Content = $NewContent
        }
    }
    
    if ($Content -ne $OriginalContent) {
        if ($DryRun) {
            Write-ColorOutput "🔍 Would fix $Changes deprecated theme patterns in: $FilePath" $Yellow
        } else {
            Set-Content -Path $FilePath -Value $Content -NoNewline
        }
        return $Changes
    }
    return 0
}

function Process-File {
    param([string]$FilePath)
    
    $TotalChanges = 0
    
    if ($Verbose) {
        Write-ColorOutput "Processing: $FilePath" $Blue
    }
    
    # Apply all fixes
    $TotalChanges += Fix-WithOpacity $FilePath
    $TotalChanges += Fix-DeprecatedWidgets $FilePath
    $TotalChanges += Fix-DeprecatedMethods $FilePath
    $TotalChanges += Fix-DeprecatedImports $FilePath
    $TotalChanges += Fix-DeprecatedTheme $FilePath
    
    return $TotalChanges
}

function Format-DartFiles {
    if (-not $DryRun) {
        Write-ColorOutput "🎨 Formatting Dart files..." $Blue
        try {
            & flutter format lib/
            Write-ColorOutput "✅ Dart files formatted" $Green
        } catch {
            Write-ColorOutput "⚠️ Warning: Could not format Dart files. Run 'flutter format lib/' manually." $Yellow
        }
    }
}

function Analyze-Project {
    if (-not $DryRun) {
        Write-ColorOutput "🔍 Analyzing project for remaining issues..." $Blue
        try {
            & flutter analyze
            Write-ColorOutput "✅ Project analysis complete" $Green
        } catch {
            Write-ColorOutput "⚠️ Warning: Project analysis found issues. Review the output above." $Yellow
        }
    }
}

# Main execution
function Main {
    Write-ColorOutput "🚀 Flutter Deprecated Code Fixer" $Blue
    Write-ColorOutput "=================================" $Blue
    
    if ($DryRun) {
        Write-ColorOutput "🔍 DRY RUN MODE - No files will be modified" $Yellow
    }
    
    # Change to project directory
    Set-Location $ProjectPath
    
    # Validate Flutter project
    Test-FlutterProject
    
    # Create backup
    if (-not $DryRun) {
        Backup-Files
    }
    
    # Find all Dart files
    $DartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"
    $TotalFiles = $DartFiles.Count
    $TotalChanges = 0
    $FilesChanged = 0
    
    Write-ColorOutput "📁 Found $TotalFiles Dart files to process" $Blue
    
    # Process each file
    foreach ($File in $DartFiles) {
        $Changes = Process-File $File.FullName
        if ($Changes -gt 0) {
            $TotalChanges += $Changes
            $FilesChanged++
        }
    }
    
    # Summary
    Write-ColorOutput "`n📊 SUMMARY" $Blue
    Write-ColorOutput "=========" $Blue
    Write-ColorOutput "Files processed: $TotalFiles" $Blue
    Write-ColorOutput "Files changed: $FilesChanged" $Green
    Write-ColorOutput "Total changes: $TotalChanges" $Green
    
    if ($DryRun) {
        Write-ColorOutput "`n🔍 This was a dry run. Run without -DryRun to apply changes." $Yellow
    } else {
        # Format and analyze
        Format-DartFiles
        Analyze-Project
        
        Write-ColorOutput "`n✅ Deprecated code fixes completed!" $Green
        Write-ColorOutput "📁 Backup available at: .deprecated_fix_backup/" $Blue
        Write-ColorOutput "🎯 Run 'flutter analyze' to check for any remaining issues" $Blue
    }
}

# Run the script
Main
