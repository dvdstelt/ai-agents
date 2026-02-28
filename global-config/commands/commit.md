# Commit

Stage and commit the current changes following the project's git conventions.

## Pre-flight checks

1. **Git identity**: verify `~/.gitconfig` has `user.name` and `user.email` set. If not, configure:
   ```
   git config --global user.email "dvdstelt@gmail.com"
   git config --global user.name "Dennis van der Stelt"
   ```
2. **Do not** add a `Co-Authored-By` trailer to commits.
3. **Never** commit files that live outside the current repository's working folder.
4. **Upstream tracking safety check**: run `git branch -vv` and inspect the upstream shown in brackets for the current branch.
   - If the branch is a feature/bugfix branch (i.e. not `main`, `master`, or `release-*`) and its upstream is `origin/main` or `origin/master`, **stop immediately**.
   - Explain the risk: any `git push` will target `main`/`master` on the remote.
   - Run `git branch --unset-upstream` to fix the misconfiguration, then confirm with `git branch -vv` before proceeding.
   - Only continue with the commit once the upstream is cleared or points to a non-protected branch.

## Commit message format

Add an emoji as the first character of the commit message to categorize it:

| Emoji | Meaning                          |
| ----- | -------------------------------- |
| 🚨     | Critical bug/patch               |
| 📝     | Documentation update             |
| ⚙️     | Non-codebase update (CI, config) |
| 🐛     | Bug fix                          |
| ✨     | Enhancement                      |
| ⚠️     | Breaking change in public API    |
| ⚜️     | Boyscout rule, cleanup           |
| 📦     | Package updates                  |

## Workflow

1. Run `git status` and `git diff --staged` to understand what is being committed.
2. If nothing is staged, stage the relevant files (prefer naming files explicitly over `git add -A`).
   - Before staging each file, run `git diff --ignore-all-space -- <file>`. If the output is empty, the only changes are whitespace or line endings — **do not stage that file**.
   - Never alter line endings (CRLF/LF). If a file was CRLF, it must stay CRLF. Before staging, run `git diff -- <file>` and look for `^M` markers indicating line ending changes. If every line shows a line ending change, the file's endings were altered — restore the original endings before staging so the diff only shows the real changes.
3. Compose a commit message:
   - Start with the appropriate emoji prefix
   - Summarize the "why", not the "what"
   - Keep the first line concise (under 72 characters when possible)
4. Commit the changes.
5. **After each logical code change, immediately commit before moving to the next change.** Do not batch multiple unrelated changes into a single commit.
6. **Never use `git revert` to undo a bad commit.** Instead, amend or interactively rebase to remove or fix the offending commit so history stays clean and readable.

## Rebase preflight

When rebasing onto another branch:
- Check if the local target branch is behind `origin` (e.g. `git rev-list HEAD..origin/<branch> --count`)
- If it is behind, **ask** the user whether to pull/fast-forward first before proceeding
- Rewriting history on feature branches is fully allowed and preferred (rebase, amend, squash)
