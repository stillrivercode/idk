# Stillriver AI Workflows Integration

## Overview

This document describes the integration of the [stillriver-ai-workflows](https://github.com/stillrivercode/stillriver-ai-workflows) GitHub Action into the IDK project, replacing the custom OpenRouter API implementation in the AI PR review workflow.

## What Changed

### Before

The `ai-pr-review.yml` workflow used:

- Custom Python script to call OpenRouter API directly
- Manual handling of API requests, timeouts, and retries
- Custom review comment formatting
- Direct file I/O for managing review outputs

### After

The workflow now uses:

- The `stillrivercode/stillriver-ai-workflows@v1` action
- Standardized API handling through the action
- Action-provided outputs for review content and status
- Simplified error handling

## Key Benefits

1. **Simplified Maintenance**: No need to maintain custom Python scripts for API interactions
2. **Standardized Implementation**: Uses a shared action that can be updated independently
3. **Better Error Handling**: The action provides structured status outputs
4. **Native GitHub Integration**: Designed specifically for GitHub PR reviews
5. **Resolvable Suggestions**: The action supports GitHub's native suggestion format

## Configuration

The action is configured with the following inputs:

```yaml
- uses: stillrivercode/stillriver-ai-workflows@v1
  env:
    AI_REVIEW_RATE_LIMIT_MINUTES: ${{ vars.AI_REVIEW_RATE_LIMIT_MINUTES || '1' }}
    AI_ENABLE_INLINE_COMMENTS: ${{ vars.AI_ENABLE_INLINE_COMMENTS || 'true' }}
  with:
    github_token: ${{ github.token }}
    openrouter_api_key: ${{ secrets.OPENROUTER_API_KEY }}
    model: ${{ vars.AI_MODEL || 'anthropic/claude-sonnet-4' }}
    review_type: 'full'
    max_tokens: 4096
    temperature: 0.7
    request_timeout_seconds: 600
    retries: 3
    post_comment: 'true'  # Let the action handle resolvable comments
```

## Required Secrets

- `OPENROUTER_API_KEY`: Your OpenRouter API key (already configured)

## Optional Variables

- `AI_MODEL`: The AI model to use (defaults to `anthropic/claude-sonnet-4`)
- `AI_REVIEW_RATE_LIMIT_MINUTES`: Rate limit window for reviews (defaults to `1` minute)
- `AI_ENABLE_INLINE_COMMENTS`: Enable GitHub's native inline suggestions (defaults to `true`)

## Workflow Behavior

1. The workflow triggers remain the same:
   - When a PR is opened
   - When the `ai-review-needed` label is added
   - When someone comments `/review` (if implemented)

2. The action performs the review and posts resolvable comments directly:
   - Creates GitHub's native resolvable suggestions when confidence ≥95%
   - Posts enhanced recommendations for confidence 80-94%
   - Posts regular comments for confidence 65-79%
   - Suppresses suggestions with confidence <65%

3. Post-processing steps handle:
   - Label management based on review content
   - Error handling and user notifications

## Migration Notes

- Removed Python setup and dependency installation steps
- Removed custom review prompt generation and API script
- Removed custom comment posting to enable native resolvable suggestions
- Simplified error handling to use action outputs
- Maintained all existing workflow triggers and conditions
- Preserved label management logic
- Updated rate limit check to use configurable `AI_REVIEW_RATE_LIMIT_MINUTES`
- Enabled resolvable comments via `AI_ENABLE_INLINE_COMMENTS` and `post_comment: true`

## Future Enhancements

The stillriver-ai-workflows action supports additional features that could be enabled:

- Custom review rules via JSON configuration
- File exclusion patterns
- Automatic comment posting with resolvable suggestions
- Different review types (security, performance, etc.)
