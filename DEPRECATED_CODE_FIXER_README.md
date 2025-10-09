# Flutter Deprecated Code Fixer

This script efficiently fixes deprecated Flutter/Dart code patterns, especially `withOpacity` and other common deprecations.

## Features

- ✅ **withOpacity fixes**: `color.withOpacity(0.5)` → `color.withValues(alpha: 0.5)`
- ✅ **Deprecated widgets**: `FlatButton` → `TextButton`, `RaisedButton` → `ElevatedButton`
- ✅ **Deprecated methods**: `MediaQuery.of(context).size` → `MediaQuery.sizeOf(context)`
- ✅ **Deprecated theme**: `Colors.grey[100]` → `Colors.grey.shade100`
- ✅ **Safe backup**: Creates backup before making changes
- ✅ **Dry run mode**: Preview changes without modifying files
- ✅ **Auto formatting**: Runs `flutter format` after fixes
- ✅ **Project analysis**: Runs `flutter analyze` to check for issues

## Usage

### PowerShell (Windows)
```powershell
# Dry run to see what would be changed
.\fix_deprecated_code.ps1 -DryRun

# Fix all deprecated code
.\fix_deprecated_code.ps1

# Fix with verbose output
.\fix_deprecated_code.ps1 -Verbose

# Fix specific project path
.\fix_deprecated_code.ps1 -ProjectPath "C:\path\to\flutter\project"
```

### Bash (Linux/macOS)
```bash
# Make executable first
chmod +x fix_deprecated_code.sh

# Dry run to see what would be changed
./fix_deprecated_code.sh --dry-run

# Fix all deprecated code
./fix_deprecated_code.sh

# Fix with verbose output
./fix_deprecated_code.sh --verbose

# Fix specific project path
./fix_deprecated_code.sh --path "/path/to/flutter/project"
```

## What Gets Fixed

### 1. withOpacity Patterns
```dart
// Before
Colors.black.withOpacity(0.5)
theme.colorScheme.primary.withOpacity(0.3)
MaterialStateProperty.all(color.withOpacity(0.8))

// After
Colors.black.withValues(alpha: 0.5)
theme.colorScheme.primary.withValues(alpha: 0.3)
MaterialStateProperty.all(color.withValues(alpha: 0.8))
```

### 2. Deprecated Widgets
```dart
// Before
FlatButton(onPressed: () {}, child: Text('Click'))
RaisedButton(onPressed: () {}, child: Text('Click'))
OutlineButton(onPressed: () {}, child: Text('Click'))

// After
TextButton(onPressed: () {}, child: Text('Click'))
ElevatedButton(onPressed: () {}, child: Text('Click'))
OutlinedButton(onPressed: () {}, child: Text('Click'))
```

### 3. Deprecated Methods
```dart
// Before
MediaQuery.of(context).size.width
MediaQuery.of(context).padding
Scaffold.of(context).showSnackBar(snackBar)

// After
MediaQuery.sizeOf(context).width
MediaQuery.paddingOf(context)
ScaffoldMessenger.of(context).showSnackBar(snackBar)
```

### 4. Deprecated Theme
```dart
// Before
Colors.grey[100]
Colors.grey[500]
Colors.grey[900]

// After
Colors.grey.shade100
Colors.grey.shade500
Colors.grey.shade900
```

## Safety Features

- **Backup**: Creates `.deprecated_fix_backup/` directory with all original files
- **Dry Run**: Use `-DryRun` flag to preview changes without modifying files
- **Validation**: Checks if directory is a Flutter project before proceeding
- **Error Handling**: Graceful handling of file operations and Flutter commands

## Output Example

```
🚀 Flutter Deprecated Code Fixer
=================================
✅ Flutter project detected
📁 Backup created at: .deprecated_fix_backup
📁 Found 45 Dart files to process
✅ Fixed 12 withOpacity patterns in: lib/main.dart
✅ Fixed 3 deprecated widgets in: lib/screens/home_screen.dart
✅ Fixed 5 deprecated methods in: lib/widgets/custom_button.dart

📊 SUMMARY
=========
Files processed: 45
Files changed: 12
Total changes: 23

🎨 Formatting Dart files...
✅ Dart files formatted
🔍 Analyzing project for remaining issues...
✅ Project analysis complete

✅ Deprecated code fixes completed!
📁 Backup available at: .deprecated_fix_backup/
🎯 Run 'flutter analyze' to check for any remaining issues
```

## Requirements

- Flutter SDK installed
- PowerShell 5.1+ (Windows) or Bash (Linux/macOS)
- Dart files in `lib/` directory

## Troubleshooting

### PowerShell Execution Policy
If you get execution policy errors on Windows:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Permission Denied (Linux/macOS)
```bash
chmod +x fix_deprecated_code.sh
```

### Flutter Not Found
Make sure Flutter is in your PATH:
```bash
flutter --version
```

## Contributing

To add more deprecated patterns, edit the `$Patterns` hash in the respective fix functions:

```powershell
# Add new pattern
'OldPattern\(([^)]+)\)' = 'NewPattern($1)'
```

## License

This script is provided as-is for educational and development purposes.
