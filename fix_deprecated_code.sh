#!/bin/bash
# Fix Deprecated Flutter/Dart Code Script
# Efficiently fixes withOpacity and other deprecated patterns

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROJECT_PATH="."
DRY_RUN=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            PROJECT_PATH="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -p, --path PATH     Project path (default: .)"
            echo "  -d, --dry-run       Show what would be changed without modifying files"
            echo "  -v, --verbose       Verbose output"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

test_flutter_project() {
    if [[ ! -f "$PROJECT_PATH/pubspec.yaml" ]]; then
        print_color $RED "❌ Error: Not a Flutter project. pubspec.yaml not found."
        exit 1
    fi
    print_color $GREEN "✅ Flutter project detected"
}

backup_files() {
    local backup_dir="$PROJECT_PATH/.deprecated_fix_backup"
    if [[ -d "$backup_dir" ]]; then
        rm -rf "$backup_dir"
    fi
    mkdir -p "$backup_dir"
    
    find "$PROJECT_PATH/lib" -name "*.dart" -type f | while read -r file; do
        local relative_path="${file#$PROJECT_PATH/}"
        local backup_path="$backup_dir/$relative_path"
        local backup_dir_path=$(dirname "$backup_path")
        mkdir -p "$backup_dir_path"
        cp "$file" "$backup_path"
    done
    print_color $BLUE "📁 Backup created at: $backup_dir"
}

fix_with_opacity() {
    local file_path=$1
    local temp_file=$(mktemp)
    local changes=0
    
    # Fix withOpacity patterns
    sed -E '
        # Color.withOpacity() -> Color.withValues(alpha: ...)
        s/([a-zA-Z_][a-zA-Z0-9_]*)\.withOpacity\(([^)]+)\)/\1.withValues(alpha: \2)/g
        
        # Colors.black.withOpacity() -> Colors.black.withValues(alpha: ...)
        s/Colors\.black\.withOpacity\(([^)]+)\)/Colors.black.withValues(alpha: \1)/g
        s/Colors\.white\.withOpacity\(([^)]+)\)/Colors.white.withValues(alpha: \1)/g
        
        # Theme colors with withOpacity
        s/theme\.colorScheme\.([a-zA-Z_][a-zA-Z0-9_]*)\.withOpacity\(([^)]+)\)/theme.colorScheme.\1.withValues(alpha: \2)/g
        
        # MaterialStateProperty.withOpacity
        s/MaterialStateProperty\.all\(([^)]+)\.withOpacity\(([^)]+)\)\)/MaterialStateProperty.all(\1.withValues(alpha: \2))/g
    ' "$file_path" > "$temp_file"
    
    if ! cmp -s "$file_path" "$temp_file"; then
        local diff_count=$(diff "$file_path" "$temp_file" | grep -c "^[<>]" || true)
        changes=$((diff_count / 2))
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_color $YELLOW "🔍 Would fix $changes withOpacity patterns in: $file_path"
        else
            cp "$temp_file" "$file_path"
            print_color $GREEN "✅ Fixed $changes withOpacity patterns in: $file_path"
        fi
    fi
    
    rm -f "$temp_file"
    echo $changes
}

fix_deprecated_widgets() {
    local file_path=$1
    local temp_file=$(mktemp)
    local changes=0
    
    # Fix deprecated widget patterns
    sed -E '
        # FlatButton -> TextButton
        s/FlatButton\(/TextButton(/g
        s/FlatButton\.icon\(/TextButton.icon(/g
        
        # RaisedButton -> ElevatedButton
        s/RaisedButton\(/ElevatedButton(/g
        s/RaisedButton\.icon\(/ElevatedButton.icon(/g
        
        # OutlineButton -> OutlinedButton
        s/OutlineButton\(/OutlinedButton(/g
        s/OutlineButton\.icon\(/OutlinedButton.icon(/g
        
        # ButtonTheme -> ButtonStyle
        s/ButtonTheme\.of\(context\)/ButtonStyle.of(context)/g
        
        # Deprecated EdgeInsets
        s/EdgeInsets\.fromLTRB\(/EdgeInsets.fromLTRB(/g
    ' "$file_path" > "$temp_file"
    
    if ! cmp -s "$file_path" "$temp_file"; then
        local diff_count=$(diff "$file_path" "$temp_file" | grep -c "^[<>]" || true)
        changes=$((diff_count / 2))
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_color $YELLOW "🔍 Would fix $changes deprecated widgets in: $file_path"
        else
            cp "$temp_file" "$file_path"
            print_color $GREEN "✅ Fixed $changes deprecated widgets in: $file_path"
        fi
    fi
    
    rm -f "$temp_file"
    echo $changes
}

fix_deprecated_methods() {
    local file_path=$1
    local temp_file=$(mktemp)
    local changes=0
    
    # Fix deprecated method patterns
    sed -E '
        # Deprecated Navigator methods
        s/Navigator\.of\(context\)\.pushReplacementNamed\(/Navigator.of(context).pushReplacement(/g
        s/Navigator\.of\(context\)\.pushNamedAndRemoveUntil\(/Navigator.of(context).pushAndRemoveUntil(/g
        
        # Deprecated MediaQuery
        s/MediaQuery\.of\(context\)\.size\.width/MediaQuery.sizeOf(context).width/g
        s/MediaQuery\.of\(context\)\.size\.height/MediaQuery.sizeOf(context).height/g
        s/MediaQuery\.of\(context\)\.padding/MediaQuery.paddingOf(context)/g
        
        # Deprecated Scaffold.of
        s/Scaffold\.of\(context\)\.showSnackBar\(/ScaffoldMessenger.of(context).showSnackBar(/g
    ' "$file_path" > "$temp_file"
    
    if ! cmp -s "$file_path" "$temp_file"; then
        local diff_count=$(diff "$file_path" "$temp_file" | grep -c "^[<>]" || true)
        changes=$((diff_count / 2))
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_color $YELLOW "🔍 Would fix $changes deprecated methods in: $file_path"
        else
            cp "$temp_file" "$file_path"
            print_color $GREEN "✅ Fixed $changes deprecated methods in: $file_path"
        fi
    fi
    
    rm -f "$temp_file"
    echo $changes
}

fix_deprecated_theme() {
    local file_path=$1
    local temp_file=$(mktemp)
    local changes=0
    
    # Fix deprecated theme patterns
    sed -E '
        # Deprecated color properties
        s/Colors\.grey\[100\]/Colors.grey.shade100/g
        s/Colors\.grey\[200\]/Colors.grey.shade200/g
        s/Colors\.grey\[300\]/Colors.grey.shade300/g
        s/Colors\.grey\[400\]/Colors.grey.shade400/g
        s/Colors\.grey\[500\]/Colors.grey.shade500/g
        s/Colors\.grey\[600\]/Colors.grey.shade600/g
        s/Colors\.grey\[700\]/Colors.grey.shade700/g
        s/Colors\.grey\[800\]/Colors.grey.shade800/g
        s/Colors\.grey\[900\]/Colors.grey.shade900/g
    ' "$file_path" > "$temp_file"
    
    if ! cmp -s "$file_path" "$temp_file"; then
        local diff_count=$(diff "$file_path" "$temp_file" | grep -c "^[<>]" || true)
        changes=$((diff_count / 2))
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_color $YELLOW "🔍 Would fix $changes deprecated theme patterns in: $file_path"
        else
            cp "$temp_file" "$file_path"
            print_color $GREEN "✅ Fixed $changes deprecated theme patterns in: $file_path"
        fi
    fi
    
    rm -f "$temp_file"
    echo $changes
}

process_file() {
    local file_path=$1
    local total_changes=0
    
    if [[ "$VERBOSE" == "true" ]]; then
        print_color $BLUE "Processing: $file_path"
    fi
    
    # Apply all fixes
    local changes1=$(fix_with_opacity "$file_path")
    local changes2=$(fix_deprecated_widgets "$file_path")
    local changes3=$(fix_deprecated_methods "$file_path")
    local changes4=$(fix_deprecated_theme "$file_path")
    
    total_changes=$((changes1 + changes2 + changes3 + changes4))
    echo $total_changes
}

format_dart_files() {
    if [[ "$DRY_RUN" == "false" ]]; then
        print_color $BLUE "🎨 Formatting Dart files..."
        if flutter format lib/ >/dev/null 2>&1; then
            print_color $GREEN "✅ Dart files formatted"
        else
            print_color $YELLOW "⚠️ Warning: Could not format Dart files. Run 'flutter format lib/' manually."
        fi
    fi
}

analyze_project() {
    if [[ "$DRY_RUN" == "false" ]]; then
        print_color $BLUE "🔍 Analyzing project for remaining issues..."
        if flutter analyze >/dev/null 2>&1; then
            print_color $GREEN "✅ Project analysis complete"
        else
            print_color $YELLOW "⚠️ Warning: Project analysis found issues. Review the output above."
        fi
    fi
}

main() {
    print_color $BLUE "🚀 Flutter Deprecated Code Fixer"
    print_color $BLUE "================================="
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_color $YELLOW "🔍 DRY RUN MODE - No files will be modified"
    fi
    
    # Change to project directory
    cd "$PROJECT_PATH"
    
    # Validate Flutter project
    test_flutter_project
    
    # Create backup
    if [[ "$DRY_RUN" == "false" ]]; then
        backup_files
    fi
    
    # Find all Dart files
    local dart_files=($(find lib -name "*.dart" -type f))
    local total_files=${#dart_files[@]}
    local total_changes=0
    local files_changed=0
    
    print_color $BLUE "📁 Found $total_files Dart files to process"
    
    # Process each file
    for file in "${dart_files[@]}"; do
        local changes=$(process_file "$file")
        if [[ $changes -gt 0 ]]; then
            total_changes=$((total_changes + changes))
            files_changed=$((files_changed + 1))
        fi
    done
    
    # Summary
    print_color $BLUE ""
    print_color $BLUE "📊 SUMMARY"
    print_color $BLUE "========="
    print_color $BLUE "Files processed: $total_files"
    print_color $GREEN "Files changed: $files_changed"
    print_color $GREEN "Total changes: $total_changes"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_color $YELLOW ""
        print_color $YELLOW "🔍 This was a dry run. Run without --dry-run to apply changes."
    else
        # Format and analyze
        format_dart_files
        analyze_project
        
        print_color $GREEN ""
        print_color $GREEN "✅ Deprecated code fixes completed!"
        print_color $BLUE "📁 Backup available at: .deprecated_fix_backup/"
        print_color $BLUE "🎯 Run 'flutter analyze' to check for any remaining issues"
    fi
}

# Run the script
main
