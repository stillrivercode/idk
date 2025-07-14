# push

**Category**: Git Operations

**Definition**: When a user issues a `push` command, they are asking you to push local commits to a remote repository, optionally creating or updating remote branches.

## Example Prompts

- `push my changes to the main branch`
- `push this feature branch and set up tracking`
- `push with force-with-lease to update the remote branch safely`

## Expected Output Format

```markdown
# Git Push: [Branch/Target Description]

## Commands Executed
```bash
git push -u origin feature/user-auth
```markdown

## Push Output

```markdown
Enumerating objects: 15, done.
Counting objects: 100% (15/15), done.
Delta compression using up to 8 threads
Compressing objects: 100% (8/8), done.
Writing objects: 100% (9/9), 1.23 KiB | 1.23 MiB/s, done.
Total 9 (delta 3), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (3/3), completed with 2 local objects.
To https://github.com/owner/repo.git
 * [new branch]      feature/user-auth -> feature/user-auth
branch 'feature/user-auth' set up to track 'origin/feature/user-auth'.
```markdown

## Results

- **Remote**: origin (<https://github.com/owner/repo.git>)
- **Branch**: feature/user-auth → origin/feature/user-auth
- **Commits**: 3 new commits pushed
- **Status**: ✅ Success

## Branch Tracking

- ✅ Upstream tracking configured
- Future `git push` will target origin/feature/user-auth
- Future `git pull` will merge from origin/feature/user-auth

```markdown

## Push Strategies

- **Simple Push**: `git push` (when tracking is set up)
- **First Push**: `git push -u origin branch-name` (sets up tracking)
- **Force Push**: `git push --force-with-lease` (safer than --force)
- **Delete Remote**: `git push origin --delete branch-name`

## Safety Considerations

- Always verify target branch before pushing
- Use `--force-with-lease` instead of `--force` when rewriting history
- Consider branch protection rules and team policies
- Check for unpulled changes before force pushing

## Usage Notes

- Requires write access to the target repository
- May trigger CI/CD pipelines and webhooks
- Updates remote tracking branches
- Can create new remote branches when pushing for first time

## Related Commands

- [**commit**](commit.md) - Create commits before pushing
- [**pr**](pr.md) - Create pull requests after pushing
- [**gh**](gh.md) - GitHub operations after pushing
