# Commit conventions

The goal of the commit convention is to have the git history in a unified form and to be able to generate automated changelogs from it.

The form of the commit shall follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

Only the following types should be used.

## Commit types

| Type     |    Title                 |  Description |
|----------|--------------------------|------|
| `feat`     | Features	              | A new feature |
| `fix`      | Bug Fixes	              | A bug Fix |
| `docs`     | Documentation            | Documentation only changes |
| `style`    | Styles	                  | Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc) |
| `refactor` | Code Refactoring         |	A code change that neither fixes a bug nor adds a feature |
| `perf`     | Performance Improvements |	A code change that improves performance |
| `test`     | Tests                    |	Adding missing tests or correcting existing tests |
| `build`    | Builds                   |	Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm) |
| `ci`       | Continuous Integrations  |	Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs) |
| `chore`    | Chores                   |	Other changes that don't modify src or test files |
| `revert`   | Reverts                  |	Reverts a previous |