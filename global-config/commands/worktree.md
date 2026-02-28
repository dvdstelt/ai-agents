# Create Worktree

Set up a git worktree for parallel work on the current repo.

## Naming convention

Worktrees are created as sibling directories under `/workspace/` using `@` as separator:

```
/workspace/NServiceBus/              # main checkout
/workspace/NServiceBus@feature-x/    # worktree for feature-x branch
/workspace/NServiceBus@bugfix-y/     # worktree for bugfix-y branch
```

## Creating a worktree

**Always use `git-wtadd`** instead of `git worktree add`:

```
cd /workspace/RepoName
git-wtadd /workspace/RepoName@branch-name branch-name
```

`git-wtadd` rewrites worktree metadata for cross-platform use:
1. The `.git` file in the worktree root uses **relative paths**, so basic git operations work on both Linux and Windows.
2. The `gitdir` file in `.git/worktrees/<name>/` is rewritten to the **Windows host path**, so `git worktree list`, GitKraken, and other Windows tools recognize the worktree natively.

This works because the Docker launcher mounts the **parent** of the current project folder as `/workspace`. Worktrees created as siblings are visible on the host machine alongside the original project folder.

## Working in a worktree

- **All commits go to the worktree branch; no exceptions.** Do not switch to the main checkout to commit anything. If a change feels like it "doesn't belong in the worktree", that reasoning is wrong. Commit it to the worktree branch. If genuinely unsure, ask the user.
- Never modify files in the main repo checkout (`/workspace/RepoName/`). Keep it clean for the user.
- When the agent's work is complete, the branch can be merged into the main checkout only if there are no uncommitted changes there.

## Removing a worktree

Because `gitdir` contains a Windows path, `git worktree remove` does not work inside the container. Remove worktrees manually:

```
rm -rf /workspace/RepoName@branch-name
rm -rf /workspace/RepoName/.git/worktrees/RepoName@branch-name
```

Automatic `git gc` is disabled inside the container (`gc.auto=0`) to prevent incorrect pruning.

## When to use worktrees

Use your discretion, but prefer worktrees when parallelizing work, especially when long-running tests or builds are involved. Worktrees allow multiple agents to work on the same repo simultaneously without conflicts.
