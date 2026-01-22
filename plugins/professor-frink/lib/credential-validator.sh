#!/bin/bash
# credential-validator.sh - Validate required credentials for Professor Frink
#
# Usage:
#   ./credential-validator.sh validate    - Validate all required credentials
#   ./credential-validator.sh init        - Create default credentials config
#   ./credential-validator.sh list        - List required credentials
#   ./credential-validator.sh check <var> - Check specific variable

set -e

FRINK_DIR=".frink"
CREDENTIALS_FILE="$FRINK_DIR/credentials.yml"

# Initialize credentials file with defaults
init_credentials() {
    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        mkdir -p "$FRINK_DIR"
        cat > "$CREDENTIALS_FILE" << 'EOF'
# Professor Frink Credentials Configuration
# Define required and optional environment variables

credentials:
  required_env_vars:
    # AWS credentials for infrastructure deployment
    # - AWS_ACCESS_KEY_ID
    # - AWS_SECRET_ACCESS_KEY
    # - AWS_REGION

    # Uncomment and add your required credentials
    # - GITHUB_TOKEN
    # - DATABASE_URL

  optional_env_vars:
    # Optional integrations
    # - SLACK_WEBHOOK_URL
    # - SENTRY_DSN
    # - DATADOG_API_KEY

# Validation rules
validation:
  # Fail immediately if required vars are missing
  fail_fast: true

  # Show values (masked) when validating
  show_masked_values: true

  # Custom validation patterns
  patterns:
    AWS_ACCESS_KEY_ID: "^AKIA[A-Z0-9]{16}$"
    AWS_SECRET_ACCESS_KEY: "^[A-Za-z0-9/+=]{40}$"
EOF
        echo "Created credentials config: $CREDENTIALS_FILE"
    fi
}

# Parse required vars from YAML (simple parser)
get_required_vars() {
    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        return
    fi

    local in_required=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*required_env_vars: ]]; then
            in_required=true
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*optional_env_vars: ]]; then
            in_required=false
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*[a-z_]+: && ! "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            in_required=false
            continue
        fi
        if [[ "$in_required" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*([A-Z_]+) ]]; then
            # Skip commented lines
            if [[ ! "$line" =~ ^[[:space:]]*#[[:space:]]*- ]]; then
                echo "${BASH_REMATCH[1]}"
            fi
        fi
    done < "$CREDENTIALS_FILE"
}

# Parse optional vars from YAML
get_optional_vars() {
    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        return
    fi

    local in_optional=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*optional_env_vars: ]]; then
            in_optional=true
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*[a-z_]+: && ! "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            in_optional=false
            continue
        fi
        if [[ "$in_optional" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*([A-Z_]+) ]]; then
            # Skip commented lines
            if [[ ! "$line" =~ ^[[:space:]]*#[[:space:]]*- ]]; then
                echo "${BASH_REMATCH[1]}"
            fi
        fi
    done < "$CREDENTIALS_FILE"
}

# Mask a value for display
mask_value() {
    local value="$1"
    local len=${#value}

    if [[ $len -le 4 ]]; then
        echo "****"
    elif [[ $len -le 8 ]]; then
        echo "${value:0:2}****"
    else
        echo "${value:0:4}****${value: -4}"
    fi
}

# Check if a variable matches its pattern (if defined)
check_pattern() {
    local var_name="$1"
    local value="$2"

    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        return 0
    fi

    # Look for pattern in config
    local pattern=$(grep -A1 "$var_name:" "$CREDENTIALS_FILE" 2>/dev/null | tail -1 | tr -d '"' | tr -d "'" | xargs)

    if [[ -n "$pattern" && "$pattern" =~ ^\^ ]]; then
        if [[ "$value" =~ $pattern ]]; then
            return 0
        else
            return 1
        fi
    fi

    return 0
}

# Validate a single variable
check_var() {
    local var_name="$1"
    local value="${!var_name:-}"

    if [[ -z "$value" ]]; then
        echo "MISSING"
        return 1
    fi

    if ! check_pattern "$var_name" "$value"; then
        echo "INVALID_FORMAT"
        return 2
    fi

    echo "OK"
    return 0
}

# Validate all credentials
validate_all() {
    init_credentials

    local has_errors=false
    local missing_vars=()
    local invalid_vars=()

    echo ""
    echo "Credential Validation"
    echo "====================="
    echo ""

    # Check required vars
    echo "Required Variables:"
    local required_vars=($(get_required_vars))

    if [[ ${#required_vars[@]} -eq 0 ]]; then
        echo "  (none configured)"
    else
        for var in "${required_vars[@]}"; do
            local status=$(check_var "$var")
            local value="${!var:-}"

            case $status in
                OK)
                    local masked=$(mask_value "$value")
                    echo "  [OK]      $var = $masked"
                    ;;
                MISSING)
                    echo "  [MISSING] $var"
                    missing_vars+=("$var")
                    has_errors=true
                    ;;
                INVALID_FORMAT)
                    echo "  [INVALID] $var (format mismatch)"
                    invalid_vars+=("$var")
                    has_errors=true
                    ;;
            esac
        done
    fi

    echo ""

    # Check optional vars
    echo "Optional Variables:"
    local optional_vars=($(get_optional_vars))

    if [[ ${#optional_vars[@]} -eq 0 ]]; then
        echo "  (none configured)"
    else
        for var in "${optional_vars[@]}"; do
            local value="${!var:-}"

            if [[ -z "$value" ]]; then
                echo "  [SKIP]    $var (not set)"
            else
                local masked=$(mask_value "$value")
                echo "  [OK]      $var = $masked"
            fi
        done
    fi

    echo ""

    # Summary
    if [[ "$has_errors" == true ]]; then
        echo "========================================"
        echo "  VALIDATION FAILED"
        echo "========================================"
        echo ""

        if [[ ${#missing_vars[@]} -gt 0 ]]; then
            echo "Missing required variables:"
            for var in "${missing_vars[@]}"; do
                echo "  - $var"
            done
            echo ""
            echo "Set these variables before running:"
            for var in "${missing_vars[@]}"; do
                echo "  export $var=\"your-value-here\""
            done
        fi

        if [[ ${#invalid_vars[@]} -gt 0 ]]; then
            echo ""
            echo "Invalid format:"
            for var in "${invalid_vars[@]}"; do
                echo "  - $var"
            done
        fi

        echo ""
        return 1
    else
        echo "========================================"
        echo "  VALIDATION PASSED"
        echo "========================================"
        echo ""
        return 0
    fi
}

# List all credentials
list_credentials() {
    init_credentials

    echo "Credentials Configuration"
    echo "========================="
    echo ""
    echo "Config file: $CREDENTIALS_FILE"
    echo ""

    echo "Required:"
    local required_vars=($(get_required_vars))
    if [[ ${#required_vars[@]} -eq 0 ]]; then
        echo "  (none)"
    else
        for var in "${required_vars[@]}"; do
            echo "  - $var"
        done
    fi

    echo ""
    echo "Optional:"
    local optional_vars=($(get_optional_vars))
    if [[ ${#optional_vars[@]} -eq 0 ]]; then
        echo "  (none)"
    else
        for var in "${optional_vars[@]}"; do
            echo "  - $var"
        done
    fi
}

# Main command dispatch
case "${1:-}" in
    init)
        init_credentials
        ;;
    validate)
        validate_all
        ;;
    list)
        list_credentials
        ;;
    check)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 check <VAR_NAME>" >&2
            exit 1
        fi
        result=$(check_var "$2")
        echo "$2: $result"
        [[ "$result" == "OK" ]]
        ;;
    *)
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  init      Create default credentials config"
        echo "  validate  Validate all required credentials"
        echo "  list      List configured credentials"
        echo "  check <var> Check specific variable"
        exit 1
        ;;
esac
