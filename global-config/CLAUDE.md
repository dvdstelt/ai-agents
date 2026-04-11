# Global Claude Preferences

## Version Control

- **Do not** co-author commits
- Build context from git history when working in a repo
- If on `main`, `master`, or `release-*` — suggest working on a feature branch before making changes
- **Never** push to `main`, `master`, or `release-*`
- **Never** commit directly to `main`, `master`, or `release-*` — always work on a feature branch. This is an absolute rule with zero exceptions. There is no scenario — not a "quick fix", not a "config change", not something that "doesn't belong in the worktree" — that justifies committing to a protected branch. If you believe a change must go to `main`, stop and ask the user instead.
- **Never** suggest staging or committing files that live outside the current repository's working folder
- **After each logical code change, immediately stage and commit before moving to the next change.** Do not batch multiple unrelated changes into a single commit.
- When committing, use the `/commit` command for emoji prefixes, git identity setup, and commit workflow
- When creating worktrees, use the `/worktree` command for naming conventions and setup instructions

## Versioning

- Review repo tags (`git tag`) to understand what versioning scheme a repo uses
- Favor [Semantic Versioning 2.0.0](https://semver.org/) — breaking = major, feature = minor, fix = patch
- Follow SemVer for version bumps unless no versions have been tagged yet or the project is still in pre-release
- Pre-release suffixes (e.g., `-alpha`, `-beta`, `-preview`) are allowed and should follow alphabetical ordering for correct package sorting. `-preview` is the last pre-release stage before stable — do not use suffixes that sort alphabetically after it (e.g., avoid `-rc`)
- On feature branches, include branch metadata in the pre-release version when possible (e.g., `1.0.0-feature-name.1`) to distinguish builds from the main line
- **Tags:** creating local tags is allowed (non-version tags and pre-release tags). **Never push tags.**
- Particular/NServiceBus repos follow SemVer — tools like MinVer are only used to derive the package version from git history/tags

## .NET

- **.NET 10** (latest) is installed in the container and should be used for .NET applications
- Use `global.json` with `"rollForward": "latestFeature"` to allow minor version flexibility

## NServiceBus Project Conventions

- Particular repos use `Particular.Analyzers` for code style enforcement
- Code style is enforced via `.editorconfig` and `EnforceCodeStyleInBuild`
- Warnings treated as errors in Release builds
- Nullable reference types typically enabled
- C# latest features used (primary constructors, collection expressions)
- Individual projects have their own `AGENTS.md` — check for it before working in a subdirectory
  - It is possible there are `claude.md` files, you can rename those to `AGENTS.md`
- **Use `AGENTS.md` (not `CLAUDE.md`) in git repositories** — repo-level agent instructions should be tool-agnostic and address any AI coding agent, not just Claude. `CLAUDE.md` is only for workspace-level Claude Code configuration.

## Plans

When starting non-trivial work (a feature branch, a migration, a multi-phase task):

- Create a plan file at `/workspace/plan-<branch-name>.md`, where `<branch-name>` mirrors the git branch with `/` replaced by `-` (e.g. branch `feature/astro-migration` → `plan-feature-astro-migration.md`)
- The file must be stored in `/workspace/` so it is visible on the host machine and survives container restarts
- Structure: start with an **Overview** and **Key Constraints** section summarising the goal and non-negotiables, followed by numbered **phases**, each containing steps as Markdown checkboxes (`- [ ]`)
- **Keep the plan current**: tick off steps (`- [x]`) as they are completed; add new steps if scope grows
- **Do not** commit the plan file to the repository — it lives only in `/workspace/`

## Destructive Operations

These rules apply at all times, including when running with `--dangerously-skip-permissions`:

- **Never delete a directory** (via `rm -rf`, `Remove-Item -Recurse`, or any equivalent) unless it is inside a git repository. If the target path is not within a git repo, stop and ask the user first.
- **Never delete more than a small number of individual files at once** without confirming with the user. Deleting a handful of generated/temporary files is fine; wiping a tree of source files is not.
- **Never run `git reflog expire`, `git gc --prune=all`, or any command that can permanently discard git history** without explicit user confirmation.
- **Never drop database tables, truncate data files, or overwrite backup files** without explicit user confirmation.
- When in doubt about whether an operation is reversible, treat it as irreversible and ask first.

## Writing Style

- Never use typographic/curly quotes (' ' " ") — always use straight quotes (' ") instead
- Never use em-dashes (—) or double-hyphens (--) as punctuation; use a comma, semicolon, colon, or rewrite the sentence instead

## NuGet

- NuGet packages can be retrieved from nuget.org or via the Particular Software private feed at `https://f.feedz.io/particular-software/packages/nuget/index.json`

@RTK.md
