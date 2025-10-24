#!/bin/bash

# ChatOps Terraform Module Setup Script
# Creates Lambda ZIPs and runs Terraform deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_SOURCE_DIR="$SCRIPT_DIR/../chatops-state-manager/lambda"
OUTPUT_DIR="$SCRIPT_DIR/lambda-zips"
TERRAFORM_DIR="$SCRIPT_DIR/target-module"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create Lambda ZIP
create_lambda_zip() {
    local lambda_name="$1"
    local source_dir="$2"
    local zip_file="$3"
    
    print_status "Creating ZIP for $lambda_name..."
    
    if [ ! -d "$source_dir" ]; then
        print_error "Source directory $source_dir does not exist!"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$zip_file")"
    
    # Create ZIP file
    cd "$source_dir"
    zip -r "$zip_file" . -x "*.pyc" "__pycache__/*" "*.git*" "tests/*" "*.md" "Dockerfile*" "build.sh" "setup_webhook.sh"
    
    if [ $? -eq 0 ]; then
        print_success "Created $zip_file ($(du -h "$zip_file" | cut -f1))"
    else
        print_error "Failed to create $zip_file"
        return 1
    fi
}

# Function to validate required tools
validate_requirements() {
    print_status "Validating requirements..."
    
    local missing_tools=()
    
    if ! command_exists zip; then
        missing_tools+=("zip")
    fi
    
    if ! command_exists terraform; then
        missing_tools+=("terraform")
    fi
    
    if ! command_exists aws; then
        missing_tools+=("aws")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install the missing tools and try again."
        exit 1
    fi
    
    print_success "All required tools are available"
}

# Function to check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS credentials not configured or invalid"
        print_error "Please run 'aws configure' or set AWS environment variables"
        exit 1
    fi
    
    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_region=$(aws configure get region || echo "us-east-1")
    
    print_success "AWS credentials valid (Account: $aws_account, Region: $aws_region)"
}

# Function to create all Lambda ZIPs
create_lambda_zips() {
    print_status "Creating Lambda ZIP files..."
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Create ZIPs for each Lambda
    create_lambda_zip "webhook-handler" "$LAMBDA_SOURCE_DIR/webhook-handler/src" "$OUTPUT_DIR/webhook-handler.zip"
    create_lambda_zip "telegram-bot" "$LAMBDA_SOURCE_DIR/telegram-bot/src" "$OUTPUT_DIR/telegram-bot.zip"
    create_lambda_zip "ai-output-processor" "$LAMBDA_SOURCE_DIR/ai-output-processor/src" "$OUTPUT_DIR/ai-output-processor.zip"
    
    print_success "All Lambda ZIP files created successfully"
}

# Function to run Terraform setup
run_terraform_setup() {
    print_status "Running Terraform setup..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        if [ -f "terraform.tfvars.example" ]; then
            cp "terraform.tfvars.example" "terraform.tfvars"
            print_warning "Please edit terraform.tfvars with your values before running terraform apply"
            print_warning "Required variables:"
            print_warning "  - name_prefix"
            print_warning "  - github_owner"
            print_warning "  - github_repo"
            print_warning "  - github_token"
            print_warning "  - telegram_bot_token"
            print_warning "  - authorized_chat_id"
            print_warning "  - s3_bucket_arn"
            print_warning "  - webhook_lambda_zip_path"
            print_warning "  - telegram_lambda_zip_path"
            return 0
        else
            print_error "No terraform.tfvars.example found!"
            return 1
        fi
    fi
    
    # Plan Terraform
    print_status "Running Terraform plan..."
    terraform plan
    
    # Ask for confirmation
    echo
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Applying Terraform configuration..."
        terraform apply -auto-approve
        print_success "Terraform deployment completed!"
        
        # Show outputs
        print_status "Terraform outputs:"
        terraform output
    else
        print_warning "Terraform apply cancelled"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --zips-only     Create Lambda ZIPs only (skip Terraform)"
    echo "  --terraform-only Run Terraform only (skip ZIP creation)"
    echo "  --help          Show this help message"
    echo
    echo "This script will:"
    echo "  1. Create Lambda ZIP files from source code"
    echo "  2. Initialize and run Terraform deployment"
    echo "  3. Create AWS Secrets Manager secret with your tokens"
    echo
    echo "Prerequisites:"
    echo "  - AWS CLI configured with appropriate permissions"
    echo "  - Terraform installed"
    echo "  - ZIP utility installed"
    echo "  - Source code in ../chatops-state-manager/lambda/"
}

# Main function
main() {
    local zips_only=false
    local terraform_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --zips-only)
                zips_only=true
                shift
                ;;
            --terraform-only)
                terraform_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_status "ChatOps Terraform Module Setup"
    print_status "================================"
    
    # Validate requirements
    validate_requirements
    check_aws_credentials
    
    # Create Lambda ZIPs
    if [ "$terraform_only" = false ]; then
        create_lambda_zips
    fi
    
    # Run Terraform setup
    if [ "$zips_only" = false ]; then
        run_terraform_setup
    fi
    
    print_success "Setup completed successfully!"
    
    if [ "$zips_only" = false ]; then
        echo
        print_status "Next steps:"
        print_status "1. Configure your GitHub repository webhook URL"
        print_status "2. Test the Telegram bot in your authorized chat"
        print_status "3. Monitor CloudWatch logs for any issues"
    fi
}

# Run main function with all arguments
main "$@"
