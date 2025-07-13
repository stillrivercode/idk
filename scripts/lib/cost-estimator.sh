#!/bin/bash

# Cost Estimation Library
# Provides functions to estimate and monitor AI API costs for Claude CLI and OpenRouter

set -eo pipefail

# OpenRouter pricing per 1M tokens (input:output)
# Using function-based lookup to avoid associative array compatibility issues
get_model_pricing() {
    local model="$1"
    case "$model" in
        "anthropic/claude-3.5-sonnet") echo "3.00:15.00" ;;
        "openai/gpt-4-turbo") echo "10.00:30.00" ;;
        "google/gemini-pro") echo "0.50:1.50" ;;
        "anthropic/claude-3-haiku") echo "0.25:1.25" ;;
        "anthropic/claude-3-opus") echo "15.00:75.00" ;;
        "openai/gpt-3.5-turbo") echo "0.50:1.50" ;;
        *) echo "" ;;
    esac
}

# Estimate cost for OpenRouter models
estimate_openrouter_cost() {
    local model="$1"
    local input_tokens="$2"
    local output_tokens="$3"

    local pricing=$(get_model_pricing "$model")
    if [[ -z "$pricing" ]]; then
        echo "⚠️  Warning: Unknown model pricing: $model, using Claude 3.5 Sonnet rates" >&2
        pricing=$(get_model_pricing "anthropic/claude-3.5-sonnet")
    fi

    local input_rate="${pricing%:*}"
    local output_rate="${pricing#*:}"

    # Calculate cost (rates are per 1M tokens)
    local input_cost=$(echo "scale=6; $input_tokens * $input_rate / 1000000" | bc -l)
    local output_cost=$(echo "scale=6; $output_tokens * $output_rate / 1000000" | bc -l)
    local total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc -l)

    echo "$total_cost"
}

# Update cost tracking for OpenRouter usage
update_openrouter_cost_tracking() {
    local model="$1"
    local prompt="$2"
    local response="$3"

    # Extract usage from OpenRouter response
    local usage
    usage=$(echo "$response" | jq -r '.usage // empty')

    if [[ -n "$usage" ]]; then
        local input_tokens output_tokens total_tokens
        input_tokens=$(echo "$usage" | jq -r '.prompt_tokens // 0')
        output_tokens=$(echo "$usage" | jq -r '.completion_tokens // 0')
        total_tokens=$(echo "$usage" | jq -r '.total_tokens // 0')

        local cost
        cost=$(estimate_openrouter_cost "$model" "$input_tokens" "$output_tokens")

        # Update tracking files
        update_daily_cost "$cost" "$model"
        update_monthly_cost "$cost" "$model"

        echo "💰 Cost tracking updated: \$${cost} for $total_tokens tokens ($model)"
    else
        echo "⚠️  Warning: No usage data in response, cost tracking incomplete" >&2
    fi
}

# Update daily cost tracking
update_daily_cost() {
    local cost="$1"
    local model="$2"
    local date=$(date +%Y-%m-%d)
    local cost_file="/tmp/ai_daily_costs_${date}"

    # Initialize file if it doesn't exist
    if [[ ! -f "$cost_file" ]]; then
        echo "0.000000" > "$cost_file"
    fi

    # Read current total
    local current_total=$(cat "$cost_file" 2>/dev/null || echo "0.000000")

    # Add new cost
    local new_total=$(echo "scale=6; $current_total + $cost" | bc -l)

    # Update file
    echo "$new_total" > "$cost_file"

    echo "📅 Daily cost ($date): \$${new_total}"
}

# Update monthly cost tracking
update_monthly_cost() {
    local cost="$1"
    local model="$2"
    local month=$(date +%Y-%m)
    local cost_file="/tmp/ai_monthly_costs_${month}"

    # Initialize file if it doesn't exist
    if [[ ! -f "$cost_file" ]]; then
        echo "0.000000" > "$cost_file"
    fi

    # Read current total
    local current_total=$(cat "$cost_file" 2>/dev/null || echo "0.000000")

    # Add new cost
    local new_total=$(echo "scale=6; $current_total + $cost" | bc -l)

    # Update file
    echo "$new_total" > "$cost_file"

    echo "📅 Monthly cost ($month): \$${new_total}"
}

# Get current daily cost
get_daily_cost() {
    local date=$(date +%Y-%m-%d)
    local cost_file="/tmp/ai_daily_costs_${date}"

    if [[ -f "$cost_file" ]]; then
        cat "$cost_file"
    else
        echo "0.000000"
    fi
}

# Get current monthly cost
get_monthly_cost() {
    local month=$(date +%Y-%m)
    local cost_file="/tmp/ai_monthly_costs_${month}"

    if [[ -f "$cost_file" ]]; then
        cat "$cost_file"
    else
        echo "0.000000"
    fi
}

# Estimate cost based on prompt characteristics (Legacy function for backward compatibility)
estimate_prompt_cost() {
  local prompt_file="$1"
  local model="${2:-anthropic/claude-3.5-sonnet}"

  if [[ ! -f "$prompt_file" ]]; then
    echo "⚠️  Warning: Prompt file not found for cost estimation"
    return 1
  fi

  local prompt_size=$(wc -c < "$prompt_file")
  local prompt_lines=$(wc -l < "$prompt_file")
  local prompt_words=$(wc -w < "$prompt_file")

  echo "💰 COST ESTIMATION"
  echo "----------------------------------------"
  echo "Model: $model"
  echo "Prompt size: $prompt_size characters"
  echo "Prompt lines: $prompt_lines"
  echo "Prompt words: $prompt_words"
  echo ""

  # Rough token estimation (1 token ≈ 4 characters for English text)
  local estimated_input_tokens=$((prompt_size / 4))

  # Estimate output tokens based on prompt complexity and typical response patterns
  local estimated_output_tokens
  if [[ $prompt_size -lt 1000 ]]; then
    estimated_output_tokens=$((estimated_input_tokens * 2))  # Simple tasks
  elif [[ $prompt_size -lt 5000 ]]; then
    estimated_output_tokens=$((estimated_input_tokens * 3))  # Medium tasks
  else
    estimated_output_tokens=$((estimated_input_tokens * 4))  # Complex tasks
  fi

  # Determine pricing source
  local input_cost output_cost total_cost
  local pricing=$(get_model_pricing "$model")
  if [[ -n "$pricing" ]]; then
    # Use OpenRouter pricing
    total_cost=$(estimate_openrouter_cost "$model" "$estimated_input_tokens" "$estimated_output_tokens")
    local input_rate="${pricing%:*}"
    local output_rate="${pricing#*:}"
    input_cost=$(echo "scale=4; $estimated_input_tokens * $input_rate / 1000000" | bc -l 2>/dev/null || echo "0.0000")
    output_cost=$(echo "scale=4; $estimated_output_tokens * $output_rate / 1000000" | bc -l 2>/dev/null || echo "0.0000")
  else
    # Fallback to legacy Claude pricing
    local input_cost_per_1k=0.003   # $3 per 1M tokens
    local output_cost_per_1k=0.015  # $15 per 1M tokens
    input_cost=$(echo "scale=4; $estimated_input_tokens * $input_cost_per_1k / 1000" | bc -l 2>/dev/null || echo "0.0000")
    output_cost=$(echo "scale=4; $estimated_output_tokens * $output_cost_per_1k / 1000" | bc -l 2>/dev/null || echo "0.0000")
    total_cost=$(echo "scale=4; $input_cost + $output_cost" | bc -l 2>/dev/null || echo "0.0000")
  fi

  echo "📊 Token Estimates:"
  echo "   Input tokens: ~$estimated_input_tokens"
  echo "   Output tokens: ~$estimated_output_tokens (estimated)"
  echo ""
  echo "💵 Cost Estimates (USD):"
  echo "   Input cost: \$$input_cost"
  echo "   Output cost: \$$output_cost"
  echo "   Total estimated: \$$total_cost"
  echo ""

  # Cost impact warnings
  if (( $(echo "$total_cost > 0.50" | bc -l 2>/dev/null || echo 0) )); then
    echo "⚠️  HIGH COST WARNING: Estimated cost exceeds \$0.50"
    echo "💡 Consider breaking down into smaller, focused tasks"
  elif (( $(echo "$total_cost > 0.10" | bc -l 2>/dev/null || echo 0) )); then
    echo "⚠️  MODERATE COST WARNING: Estimated cost is \$$total_cost"
    echo "💡 Review prompt complexity to optimize costs"
  else
    echo "✅ LOW COST: Estimated cost is under \$0.10"
  fi

  # Add size warnings for large prompts
  if [[ $prompt_size -gt 10000 ]]; then
    echo "⚠️  PROMPT SIZE WARNING: Large prompt detected ($prompt_size chars)"
    echo "💡 Consider breaking into smaller, focused tasks"
  fi

  echo "----------------------------------------"

  # Return cost for programmatic use
  echo "$total_cost"
}

# Track accumulated costs during session
track_session_cost() {
  local operation_cost="$1"
  local session_file="${2:-/tmp/claude_session_costs}"

  # Initialize session file if it doesn't exist
  if [[ ! -f "$session_file" ]]; then
    echo "0.0000" > "$session_file"
  fi

  # Read current session total
  local current_total=$(cat "$session_file" 2>/dev/null || echo "0.0000")

  # Add new operation cost
  local new_total=$(echo "scale=4; $current_total + $operation_cost" | bc -l 2>/dev/null || echo "$current_total")

  # Update session file
  echo "$new_total" > "$session_file"

  echo "💰 SESSION COST TRACKING"
  echo "----------------------------------------"
  echo "Operation cost: \$$operation_cost"
  echo "Session total: \$$new_total"
  echo "----------------------------------------"

  # Warn if session costs are getting high
  if (( $(echo "$new_total > 5.00" | bc -l 2>/dev/null || echo 0) )); then
    echo "🚨 SESSION COST ALERT: Total session cost (\$$new_total) exceeds \$5.00"
  elif (( $(echo "$new_total > 1.00" | bc -l 2>/dev/null || echo 0) )); then
    echo "⚠️  Session cost notice: Total session cost is \$$new_total"
  fi
}

# Generate cost optimization recommendations
suggest_cost_optimizations() {
  local prompt_file="$1"
  local estimated_cost="$2"

  echo "💡 COST OPTIMIZATION SUGGESTIONS"
  echo "----------------------------------------"

  if [[ ! -f "$prompt_file" ]]; then
    echo "Cannot provide specific suggestions without prompt file"
    return 1
  fi

  local prompt_size=$(wc -c < "$prompt_file")
  local prompt_lines=$(wc -l < "$prompt_file")

  # Analyze prompt characteristics and suggest improvements
  if [[ $prompt_size -gt 10000 ]]; then
    echo "📝 PROMPT SIZE: Large prompt detected ($prompt_size chars)"
    echo "   • Consider breaking into smaller, focused tasks"
    echo "   • Remove unnecessary context or examples"
    echo "   • Use more concise language"
    echo ""
  fi

  if [[ $prompt_lines -gt 200 ]]; then
    echo "📄 PROMPT LENGTH: Many lines detected ($prompt_lines lines)"
    echo "   • Consolidate related requirements"
    echo "   • Use bullet points instead of paragraphs"
    echo "   • Remove redundant information"
    echo ""
  fi

  # Check for potentially expensive patterns
  if grep -qi "generate.*test\|create.*test\|write.*test" "$prompt_file"; then
    echo "🧪 TEST GENERATION: Test generation can be expensive"
    echo "   • Focus on specific test cases rather than comprehensive suites"
    echo "   • Provide existing test examples to reduce AI reasoning"
    echo "   • Consider generating tests incrementally"
    echo ""
  fi

  if grep -qi "refactor\|restructure\|reorganize" "$prompt_file"; then
    echo "🔄 REFACTORING: Large refactoring tasks can be costly"
    echo "   • Start with specific modules or functions"
    echo "   • Provide clear refactoring goals and constraints"
    echo "   • Consider automated tools before AI assistance"
    echo ""
  fi

  if grep -qi "documentation\|readme\|doc" "$prompt_file"; then
    echo "📚 DOCUMENTATION: Documentation generation can vary in cost"
    echo "   • Provide documentation templates or examples"
    echo "   • Focus on specific sections rather than complete docs"
    echo "   • Use existing documentation as a reference"
    echo ""
  fi

  # General cost optimization tips
  echo "🎯 GENERAL TIPS:"
  echo "   • Use specific, actionable language"
  echo "   • Provide clear success criteria"
  echo "   • Include relevant context files rather than describing them"
  echo "   • Consider using '--quiet' flag to reduce verbose output"
  echo "   • Set appropriate timeouts to prevent runaway costs"
  echo "----------------------------------------"
}

# Cleanup cost tracking files
cleanup_cost_tracking() {
  local session_file="${1:-/tmp/claude_session_costs}"

  if [[ -f "$session_file" ]]; then
    local final_total=$(cat "$session_file" 2>/dev/null || echo "0.0000")
    echo "💰 Final session cost: \$$final_total"
    rm -f "$session_file"
    echo "🧹 Cost tracking file cleaned up"
  fi
}
