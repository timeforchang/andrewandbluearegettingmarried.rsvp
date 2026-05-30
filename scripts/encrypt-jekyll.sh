#!/bin/bash

# encrypt-jekyll.sh - Build Jekyll site and encrypt specified pages with StatiCrypt
# Usage: ./encrypt-jekyll.sh [options] page1.html page2.html [page3.html ...]
# Options:
#   --skip-build    Skip Jekyll build step
#   --config FILE   Load pages from YAML config file

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEMPLATE_FILE="src/password_template.html"
ENV_FILE=".env"
OUTPUT_DIR="src/encrypted"
SITE_DIR="build"

# Parse options
SKIP_BUILD=false
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load pages from config or args
if [ -n "$CONFIG_FILE" ]; then
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Config file '$CONFIG_FILE' not found!"
        exit 1
    fi
    print_status "Loading pages from config file: $CONFIG_FILE"
    PAGES=$(node -e "const yaml = require('js-yaml'); const fs = require('fs'); const config = yaml.load(fs.readFileSync('$CONFIG_FILE', 'utf8')); console.log(config.pages.join(' '));")
else
    PAGES="$*"
fi

# Check if any pages were provided
if [ -z "$PAGES" ]; then
    print_error "No pages specified!"
    echo "Usage: ./encrypt-jekyll.sh [options] page1.html page2.html [page3.html ...]"
    echo "Options:"
    echo "  --skip-build    Skip Jekyll build step"
    echo "  --config FILE   Load pages from YAML config file"
    echo "Example: ./encrypt-jekyll.sh --config encrypted-pages.yml"
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    print_error "Template file '$TEMPLATE_FILE' not found!"
    exit 1
fi
TEMPLATE_FILE=$(realpath "$TEMPLATE_FILE")

# Check if STATICRYPT_PASSWORD is set in environment
if [ -n "$STATICRYPT_PASSWORD" ]; then
    print_success "Password loaded from environment variable"
else
    # Fallback to .env file if environment variable is not set
    ENV_FILE=".env"
    if [ -f "$ENV_FILE" ]; then
        print_status "Loading environment variables from $ENV_FILE"
        set -a
        source "$ENV_FILE"
        set +a
        
        # Check if STATICRYPT_PASSWORD is set
        if [ -z "$STATICRYPT_PASSWORD" ]; then
            print_error "STATICRYPT_PASSWORD not found in $ENV_FILE"
            exit 1
        else
            print_success "Password loaded from .env file"
        fi
    else
        print_error "STATICRYPT_PASSWORD environment variable not set and .env file not found!"
        print_error "Please set STATICRYPT_PASSWORD environment variable or create a .env file"
        exit 1
    fi
fi

# Step 1: Build Jekyll site (if not skipped)
if [ "$SKIP_BUILD" = false ]; then
    print_status "Step 1: Building Jekyll site..."
    if bundle exec jekyll build; then
        print_success "Jekyll build completed successfully"
    else
        print_error "Jekyll build failed!"
        exit 1
    fi
else
    print_status "Skipping Jekyll build (--skip-build specified)"
fi

# Step 2: Verify the _site directory exists
if [ ! -d "$SITE_DIR" ]; then
    print_error "Directory '$SITE_DIR' not found!"
    exit 1
fi

# Step 3: Prepare file paths for encryption
print_status "Step 3: Preparing to encrypt specified pages..."
FILE_ARGS=()
MISSING_FILES=0

for page in $PAGES; do
    # Remove leading ./ if present
    page="${page#./}"
    
    # Construct full path
    FULL_PATH="$SITE_DIR/$page"
    
    if [ -f "$FULL_PATH" ]; then
        FILE_ARGS+=("$FULL_PATH")
        print_status "Found: $FULL_PATH"
    else
        print_warning "File not found: $FULL_PATH"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

# Check if we found any files to encrypt
if [ ${#FILE_ARGS[@]} -eq 0 ]; then
    print_error "No valid files found to encrypt!"
    exit 1
fi

if [ $MISSING_FILES -gt 0 ]; then
    print_warning "$MISSING_FILES file(s) not found. Continuing with existing files..."
fi

# Step 4: Run StatiCrypt on each file and save back to _site
print_status "Step 4: Encrypting files with StatiCrypt..."
print_status "Template: $TEMPLATE_FILE"

for file_path in "${FILE_ARGS[@]}"; do
    # Get the relative path (e.g., stag/index.html)
    relative_path="${file_path#$SITE_DIR/}"
    
    print_status "Encrypting: $relative_path"
    
    # Get the directory and filename
    file_dir=$(dirname "$file_path")
    filename=$(basename "$file_path")
    
    # Work in the file's directory
    pushd "$file_dir" > /dev/null
    
    # StatiCrypt saves to ./encrypted/ with same filename
    if npx staticrypt "$filename" -t "$TEMPLATE_FILE" --remember 14; then
        # Check for encrypted file in the default 'encrypted' directory
        encrypted_file="encrypted/$filename"
        
        if [ -f "$encrypted_file" ]; then
            # Replace original with encrypted version
            mv "$encrypted_file" "$filename"
            print_success "Encrypted and saved: $relative_path"
        else
            print_error "Encrypted file not found at: $encrypted_file"
            popd > /dev/null
            exit 1
        fi
        
        # Clean up the encrypted directory
        rm -rf "encrypted"
    else
        print_error "StatiCrypt encryption failed for: $relative_path"
        popd > /dev/null
        exit 1
    fi
    
    popd > /dev/null
done

print_success "Encryption completed successfully!"

# Step 5: Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
print_success "Process completed!"
echo ""
print_status "Encrypted files are in: ${GREEN}$SITE_DIR/${NC}"
echo ""
print_status "Files encrypted:"
for file in "${FILE_ARGS[@]}"; do
    # Convert back to relative path for display
    rel_path="${file#$SITE_DIR/}"
    echo "  📄 $rel_path"
done
echo ""
print_status "To deploy, upload the contents of '$OUTPUT_DIR/' to your web server"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"