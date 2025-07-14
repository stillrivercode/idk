# plan this

**Category**: Workflow Commands

**Definition**: When a user issues a `plan this` command, they are asking you to break down complex tasks or projects into detailed implementation plans with clear steps, dependencies, and timelines.

## Example Prompts

- `plan this migration from REST API to GraphQL with minimal downtime`
- `plan this feature implementation including testing and deployment strategy`
- `plan this refactoring effort to improve system performance`

## Expected Output Format

```markdown
# Implementation Plan: [Project/Feature Name]

## Overview
Brief description of what needs to be accomplished and why

## Objectives
- Primary goals and success criteria
- Key deliverables and milestones
- Definition of done

## Prerequisites
- Required resources and dependencies
- Team skills and knowledge needed
- Infrastructure and tooling requirements

## Implementation Phases

### Phase 1: [Phase Name]
**Duration**: [Estimated time]
**Dependencies**: [What must be completed first]

#### Tasks
1. **Task Name** (Priority: High/Medium/Low)
   - Detailed description
   - Acceptance criteria
   - Estimated effort
   - Assigned team/role

#### Deliverables
- Specific outputs expected
- Quality gates and checkpoints

### Phase 2: [Next Phase]
**Duration**: [Estimated time]
**Dependencies**: Phase 1 completion

#### Tasks
2. **Next Task Name** (Priority: High/Medium/Low)
   - Build on Phase 1 deliverables
   - Integration and testing focus
   - Performance optimization

## Example Timeline
```markdown

Week 1-2: Phase 1 - Foundation
├── Requirements gathering (3 days)
├── Architecture design (4 days)
└── Initial setup (3 days)

Week 3-4: Phase 2 - Core Development
├── Feature implementation (7 days)
├── Unit testing (2 days)
└── Code review (1 day)

Week 5: Phase 3 - Integration & Deployment
├── Integration testing (3 days)
├── Documentation (1 day)
└── Production deployment (1 day)

```markdown

## Risk Assessment
- **High Risk**: Critical challenges and mitigation strategies
- **Medium Risk**: Important considerations and contingencies
- **Low Risk**: Minor issues to monitor

## Dependencies
- External dependencies and their impact
- Team dependencies and coordination needs
- Technical dependencies and integration points

## Timeline
- Overall project duration
- Key milestones and deadlines
- Buffer time for unexpected issues

## Success Metrics
- How success will be measured
- Key performance indicators
- Acceptance criteria for completion
```markdown

## Planning Methodologies

- **Agile Planning**: Sprints, user stories, iterative development
- **Waterfall Planning**: Sequential phases, detailed upfront design
- **Hybrid Approach**: Combining elements for optimal project fit
- **Risk-Driven Planning**: Addressing highest risks first

## Planning Considerations

1. **Scope Definition**: Clear boundaries and requirements
2. **Resource Allocation**: Team members, time, budget
3. **Risk Management**: Identification and mitigation strategies
4. **Quality Assurance**: Testing and validation approaches
5. **Communication**: Stakeholder updates and reporting
6. **Change Management**: Handling scope and requirement changes

## Plan Types

- **Technical Implementation**: Code, architecture, integration
- **Project Management**: Timelines, resources, coordination
- **Migration Planning**: System transitions and data movement
- **Deployment Planning**: Release strategies and rollback procedures
- **Testing Strategy**: Quality assurance and validation approaches

## Usage Notes

- Plans should be detailed enough to guide implementation but flexible enough to adapt
- Include realistic time estimates with appropriate buffers
- Consider team expertise and learning curves
- Plan for testing, documentation, and deployment
- Include rollback and contingency strategies

## Related Commands

- [**spec this**](spec-this.md) - Create detailed technical specifications for planned features
- [**analyze this**](../development/analyze-this.md) - Analyze current state before planning
- [**review this**](../quality-assurance/review-this.md) - Review implementation plans for feasibility
