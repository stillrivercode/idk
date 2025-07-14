# spec this

**Category**: Workflow Commands

**Definition**: When a user issues a `spec this` command, they are asking you to create a detailed technical specification. You should analyze the current context, requirements, or problem and produce a comprehensive specification document that will be saved in the `/specs` directory.

The specification should include:

- Clear objectives and scope
- Detailed requirements (functional and non-functional)
- Technical constraints and considerations
- Implementation approach
- Success criteria
- Optional: User stories, acceptance criteria, or API specifications

## Example Prompts

- `spec this authentication system with OAuth2 support`
- `spec this data migration from MySQL to PostgreSQL`
- `spec this new feature for real-time notifications`

## Expected Output Format

```markdown
# Technical Specification: [Feature/System Name]

## Overview
Brief description of what needs to be built and why

## Requirements

### Functional Requirements
- **FR1**: User authentication via OAuth2 providers
- **FR2**: Token refresh and expiration handling
- **FR3**: Role-based access control integration

### Non-Functional Requirements
- **NFR1**: Support 10,000 concurrent users
- **NFR2**: Response time < 200ms for auth checks
- **NFR3**: 99.9% uptime availability

## Technical Design

### Architecture

[System Architecture Diagram or Description]

### Data Models
```javascript
interface User {
  id: string;
  email: string;
  roles: string[];
  createdAt: Date;
}
```

### API Endpoints

```http
POST /auth/login
GET /auth/profile
POST /auth/refresh
DELETE /auth/logout
```

## Implementation Plan

### Phase 1: Core Authentication

- OAuth2 provider integration
- User session management
- Basic role assignment

### Phase 2: Advanced Features

- Multi-factor authentication
- Advanced role management
- Audit logging

## Testing Strategy

- Unit tests for auth logic
- Integration tests for OAuth flow
- Performance testing for concurrent users
- Security testing for vulnerabilities

## Deployment Considerations

- Environment configuration
- Database migrations
- Monitoring and alerting
- Rollback procedures

## Success Criteria

- All functional requirements implemented
- Performance benchmarks met
- Security audit passed
- Documentation complete

```markdown

## Specification Types

- **Feature Specifications**: New functionality requirements
- **API Specifications**: Service interfaces and contracts
- **Architecture Specifications**: System design and structure
- **Migration Specifications**: Data or system migration plans
- **Integration Specifications**: Third-party service integrations

## Best Practices

- Include clear acceptance criteria
- Specify technical constraints and assumptions
- Consider security and performance implications
- Document dependencies and prerequisites
- Provide realistic timelines and effort estimates

## Related Commands

- [**plan this**](plan-this.md) - Create implementation plans from specifications
- [**analyze this**](../development/analyze-this.md) - Analyze existing systems for specifications
- [**document this**](../documentation/document-this.md) - Document implemented specifications
