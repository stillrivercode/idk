# Security Best Practices

This document outlines security best practices for the AI-powered workflow template, with special
emphasis on API key management and secure operations.

## API Key Security

### OpenRouter API Key Handling

The template uses OpenRouter API keys for AI model access. Follow these security practices:

#### 1. Secure Storage

#### GitHub Secrets (Recommended)

- Store API keys in GitHub repository secrets, never in code
- Use `OPENROUTER_API_KEY` secret name for consistency
- Access pattern: `${{ secrets.OPENROUTER_API_KEY }}`

#### Local Development

- Use `.env.local` for local testing (automatically excluded from git)
- Never commit `.env` files containing API keys
- Use environment variable: `OPENROUTER_API_KEY`

#### 2. Key Validation

The CLI validates API keys with the following checks:

```javascript
function validateApiKey(key) {
  // Must start with 'sk-or-' (OpenRouter format)
  if (!key.startsWith('sk-or-')) {
    return 'OpenRouter API key should start with "sk-or-"';
  }

  // Length validation (20-200 characters)
  if (key.length < 20 || key.length > 200) {
    return 'API key length is invalid';
  }

  // Character validation (base64-like)
  if (!/^[a-zA-Z0-9-_]+$/.test(key)) {
    return 'API key contains invalid characters';
  }

  return true;
}
```

#### 3. Key Rotation

- Rotate API keys regularly (recommended: every 90 days)
- Monitor API key usage through OpenRouter dashboard
- Immediately rotate if compromise is suspected
- Update both GitHub secrets and local environment

#### 4. Access Control

#### Repository Level

- Limit repository access to necessary team members
- Use branch protection rules for sensitive workflows
- Require pull request reviews for workflow changes

#### Secret Access

- Only workflows and authorized users can access secrets
- Audit secret access through GitHub's audit log
- Use environment-specific secrets for different stages

## Workflow Security

### 1. Permission Restrictions

All workflows use minimal required permissions:

```yaml
permissions:
  contents: read
  issues: write
  pull-requests: write
  actions: read
```

### 2. Input Validation

- Validate all workflow inputs and issue content
- Sanitize user input before processing
- Use allowlists for acceptable values where possible

### 3. Timeout Controls

- 30-minute maximum runtime for all AI workflows
- Step-level timeouts for long-running operations
- Automatic termination for runaway processes

### 4. Concurrency Protection

- Prevent parallel runs using concurrency groups
- Issue-specific locking prevents conflicts
- Cancel-in-progress: false to prevent data loss

## Network Security

### 1. API Endpoints

#### Allowed Domains

- `api.openrouter.ai` - OpenRouter API access
- `api.github.com` - GitHub API operations
- No other external API calls permitted

#### Rate Limiting

- Implement client-side rate limiting for API calls
- Respect OpenRouter's rate limits
- Use exponential backoff for failed requests

### 2. Webhook Security

If using webhooks (enterprise setup):

- Validate webhook signatures
- Use HTTPS only
- Implement request size limits

## Cost Security

### 1. Spending Controls

#### Daily Limits

- Default: $50 per day
- Configurable via repository variables
- Automatic shutdown when exceeded

#### Monthly Limits

- Default: $500 per month
- Tracks cumulative usage
- Alert at 80% threshold

### 2. Circuit Breaker

```javascript
// Automatic failure detection
if (consecutiveFailures >= 3) {
  triggerCircuitBreaker();
  stopAllAIOperations();
}
```

### 3. Cost Monitoring

- Real-time cost tracking in workflow logs
- Weekly cost reports via GitHub issues
- Integration with OpenRouter usage APIs

## Emergency Procedures

### 1. Emergency Stop

#### Manual Trigger

```bash
gh workflow run emergency-controls.yml -f action=emergency_stop -f reason="Security incident"
```

#### Automatic Triggers

- Cost limit exceeded
- Suspicious activity detected
- Multiple consecutive failures

### 2. Key Compromise Response

1. **Immediate Actions**
   - Revoke compromised API key in OpenRouter dashboard
   - Remove key from GitHub secrets
   - Stop all running workflows

2. **Investigation**
   - Review audit logs for unauthorized usage
   - Check repository access logs
   - Analyze workflow execution history

3. **Recovery**
   - Generate new API key
   - Update GitHub secrets
   - Restart workflows with new key
   - Document incident for future prevention

### 3. Incident Documentation

Maintain security incident log:

- Date and time of incident
- Type of security issue
- Response actions taken
- Lessons learned and improvements

## Compliance Considerations

### 1. Data Privacy

- No sensitive data stored in logs
- API responses are not persisted
- Temporary files are cleaned up automatically

### 2. Audit Requirements

- All API calls are logged
- Workflow execution history retained
- Access patterns trackable through GitHub audit log

### 3. Regulatory Compliance

#### SOC 2 Type II

- GitHub provides SOC 2 Type II compliance
- OpenRouter security documentation available

#### GDPR Considerations

- No personal data processed by default
- User-generated content in issues follows GitHub's GDPR compliance

## Security Monitoring

### 1. Automated Monitoring

#### Bandit Security Scanning

- Scans all Python code for security vulnerabilities
- Runs on every pull request
- Blocks merge on critical findings

#### Dependency Scanning

- Safety checks for known vulnerabilities
- Semgrep for additional security patterns
- Automated updates for security patches

### 2. Manual Reviews

#### Quarterly Security Reviews

- Review API key usage patterns
- Audit workflow permissions
- Update security documentation

#### Code Review Requirements

- All workflow changes require review
- Security-focused review for sensitive operations
- Document security implications

## Secure Development Practices

### 1. Input Sanitization

```python
def sanitize_issue_content(content):
    # Remove potentially dangerous content
    content = re.sub(r'<script.*?</script>', '', content, flags=re.DOTALL)
    content = re.sub(r'javascript:', '', content, flags=re.IGNORECASE)
    return content.strip()
```

### 2. Error Handling

- Never expose API keys in error messages
- Sanitize stack traces in logs
- Use generic error messages for external users

### 3. Logging

```python
# Good: Generic logging
logger.info("API request completed successfully")

# Bad: Exposes sensitive information
logger.info(f"API request with key {api_key} completed")
```

## Resources

### 1. Security Tools

- [GitHub Security Advisories](https://github.com/advisories)
- [OpenRouter Security Documentation](https://openrouter.ai/docs/security)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)

### 2. Emergency Contacts

- Repository administrators: See GitHub team settings
- OpenRouter support: <security@openrouter.ai>
- GitHub security team: <security@github.com>

### 3. Regular Updates

This document is reviewed quarterly and updated as needed. Last updated: [Current Date]

For questions or security concerns, create a confidential issue or contact repository administrators directly.
