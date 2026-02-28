# Clean Commit History

Analyze the commit history on the current feature branch and propose a cleaner, logically grouped commit history. Then interactively rewrite it after approval.

## Workflow

### 1. Determine scope

- Identify the current branch and its base branch (usually `main` or `master`)
- Abort if on `main`, `master`, or `release-*` — history rewriting is only allowed on feature branches
- Run `git log --oneline <base>..HEAD` to list all commits in scope
- If there are fewer than 3 commits, inform the user and stop — nothing to clean up

### 2. Analyze commits

For each commit in the range:
- Read the commit message and diff (`git show --stat <sha>` and `git show <sha>`)
- Categorize by: files touched, type of change (feature, bugfix, refactor, config, docs, tests)
- Identify commits that are clearly related (same files, continuation of the same logical change, fix-ups to earlier commits)

### 3. Propose groupings

Group the commits into logical units. Common patterns to look for:
- **Fixup chains**: a commit followed by one or more small fixes to the same code → squash into one
- **Feature + tests**: implementation commit followed by test commit for the same feature → combine
- **Rename/move + adapt**: a rename or restructuring followed by reference updates → combine
- **WIP / checkpoint commits**: small incremental commits building toward one feature → squash
- **Truly independent changes**: keep these as separate commits

For each proposed group:
- Suggest a commit message following the emoji prefix convention:
  - 🚨 Critical bug/patch
  - 📝 Documentation update
  - ⚙️ Non-codebase update (CI, config)
  - 🐛 Bug fix
  - ✨ Enhancement
  - ⚠️ Breaking change in public API
  - ⚜️ Boyscout rule, cleanup
  - 📦 Package updates
- List which original commits would be combined
- Briefly explain why they belong together

### 4. Present the plan

Display a clear before/after comparison:

```
Current history (N commits):
  abc1234 first commit message
  def5678 second commit message
  ...

Proposed history (M commits):
  1. ✨ <proposed message>
     ← abc1234, def5678 (reason)
  2. 🐛 <proposed message>
     ← ghi9012 (standalone)
  ...
```

Ask the user to approve, modify, or cancel.

### 5. Execute the rewrite

After approval, use `git reset --soft <base>` and recommit in the proposed groups:
- For each group, stage only the files from that group's commits and create the new commit
- Use the agreed-upon commit messages
- If any commit in the group is authored by the user (from git config), use the user as the commit author
- Otherwise, use the author of the first commit in the group
- If a group combines commits from multiple authors, add `Co-Authored-By: Name <email>` trailers for each additional author (excluding the chosen commit author)

If the approach above is too complex for the grouping (e.g., interleaved file changes), fall back to an interactive rebase todo list that the user can review.

### 6. Verify

After rewriting:
- Run `git log --oneline <base>..HEAD` to show the new history
- Run `git diff <base>..HEAD` and confirm it produces the same overall diff as before (no code was lost)

## Rules

- **Never rewrite history on `main`, `master`, or `release-*` branches**
- **Never change the overall diff** — the end state of the code must be identical before and after cleanup
- Preserve the git identity configured in `~/.gitconfig`
- If unsure about a grouping, keep commits separate rather than incorrectly merging unrelated changes
- The user always has final say on the grouping and messages before execution
