# optimize this

**Category**: Development Commands

**Definition**: When a user issues an `optimize this` command, they are asking you to improve performance, efficiency, or resource utilization. Provide specific optimizations with expected improvements and any trade-offs.

## Example Prompts

- `optimize this database query that's taking 5 seconds`
- `optimize this React component that's re-rendering too often`
- `optimize this algorithm for better time complexity`

## Expected Output Format

```markdown
# Optimization Report: [Component/System Name]

## Current Performance Analysis
- Baseline measurements and identified bottlenecks
- Profiling results and performance metrics

## Optimization Strategies
### Strategy 1: [Optimization Name]
- **Implementation**: Code changes with examples
- **Expected Improvement**: Quantified performance gains
- **Trade-offs**: Any downsides or considerations
- **Effort**: Implementation complexity (Low/Medium/High)

### Strategy 2: [Optimization Name]
- **Implementation**: Code changes with examples
- **Expected Improvement**: Quantified performance gains
- **Trade-offs**: Any downsides or considerations
- **Effort**: Implementation complexity (Low/Medium/High)

## Recommended Implementation Order
1. High-impact, low-effort optimizations first
2. Medium-impact optimizations
3. Complex optimizations requiring architectural changes

## Measurement & Validation
- How to measure the improvements
- Performance testing approach
- Success criteria and benchmarks
```markdown

## Optimization Categories

- **Algorithm Optimization**: Improve time/space complexity
- **Database Optimization**: Query optimization, indexing, caching
- **Memory Optimization**: Reduce memory usage and allocations
- **Network Optimization**: Reduce bandwidth, improve latency
- **UI/UX Optimization**: Improve rendering performance, user experience

## Common Optimization Techniques

- **Caching**: In-memory, distributed, browser caching
- **Lazy Loading**: Defer loading until needed
- **Batching**: Group operations for efficiency
- **Indexing**: Database and search optimization
- **Compression**: Reduce data size for transfer/storage
- **Memoization**: Cache expensive computation results

## Measurement Tools

- **Profilers**: CPU, memory, and performance profilers
- **Benchmarking**: Before/after performance comparisons
- **Monitoring**: Real-time performance metrics
- **Load Testing**: Stress testing under realistic conditions

## Usage Notes

- Always measure before optimizing
- Focus on the biggest bottlenecks first
- Consider maintainability vs. performance trade-offs
- Document optimization decisions and their rationale

## Related Commands

- [**analyze this**](analyze-this.md) - Identify optimization opportunities
- [**debug this**](debug-this.md) - Debug performance issues
- [**test this**](../quality-assurance/test-this.md) - Create performance tests
