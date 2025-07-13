#!/bin/bash

# AI API Detection Library
# Provides functions to validate AI API configuration and connectivity
# Currently supports OpenRouter API (replaced Claude CLI)

set -euo pipefail

# Detect OpenRouter API configuration
detect_openrouter_api() {
  echo "🔍 OPENROUTER API DETECTION"
  echo "----------------------------------------"

  if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    echo "❌ OpenRouter API key not found"
    echo "   Set OPENROUTER_API_KEY environment variable"
    return 1
  fi

  if [[ ! "${OPENROUTER_API_KEY}" =~ ^sk-or-[a-zA-Z0-9_-]{32,}$ ]]; then
    echo "❌ Invalid OpenRouter API key format"
    return 1
  fi

  echo "✅ OpenRouter API key configured"
  echo "   Model: ${AI_MODEL:-anthropic/claude-3.5-sonnet}"
  echo "   Using direct API calls (no CLI required)"
  echo "----------------------------------------"
  echo ""

  return 0
}

# Get detailed information about OpenRouter API
get_openrouter_api_info() {
  echo "🔍 OPENROUTER API INFORMATION"
  echo "----------------------------------------"
  echo "API Endpoint: https://openrouter.ai/api/v1/chat/completions"
  echo "Model: ${AI_MODEL:-anthropic/claude-3.5-sonnet}"
  echo "Authentication: Bearer token"

  if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
    echo "API Key: ✅ Configured (${#OPENROUTER_API_KEY} characters)"

    # Test API connectivity
    if command -v curl >/dev/null 2>&1; then
      echo ""
      echo "📋 API Connectivity Test:"
      local test_response
      test_response=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer ${OPENROUTER_API_KEY}" \
        --connect-timeout 5 --max-time 10 \
        https://openrouter.ai/api/v1/models 2>/dev/null || echo "000")

      case "$test_response" in
        200) echo "   ✅ API connectivity: OK" ;;
        401) echo "   ❌ API connectivity: Authentication failed" ;;
        *) echo "   ⚠️  API connectivity: Cannot verify (${test_response})" ;;
      esac
    fi
  else
    echo "API Key: ❌ Not configured"
  fi

  echo "----------------------------------------"
  echo ""
}

# Validate environment for OpenRouter API execution
validate_environment() {
  echo "🔧 ENVIRONMENT VALIDATION"
  echo "----------------------------------------"
  echo "OPENROUTER_API_KEY: $(if [ -n "${OPENROUTER_API_KEY:-}" ]; then echo "✅ Set (${#OPENROUTER_API_KEY} characters)"; else echo "❌ Not set"; fi)"
  echo "AI_MODEL: ${AI_MODEL:-anthropic/claude-3.5-sonnet}"
  echo "GITHUB_TOKEN: $(if [ -n "${GITHUB_TOKEN:-}" ]; then echo "✅ Set (${#GITHUB_TOKEN} characters)"; else echo "❌ Not set"; fi)"
  echo "----------------------------------------"
  echo ""
}
