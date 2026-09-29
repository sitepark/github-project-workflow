# Setup for composer projects

See [github-composer-release-test](https://github.com/sitepark/github-composer-release-test){:target="\_blank"} as an example project.

## Manage access

In [packagist.org](https://packagist.org/){:target="\_blank"} a user `sitepark` is created. It is linked to the GitHub user `sitepark-bot` to manage the webhooks for packagist.org. See also: [How to update packages?](https://packagist.org/about#how-to-update-packages){:target="\_blank"}

To manage the webhook of a composer project, the `sitepark-bot` needs the **admin** role on the project. It gets this role through the team `bots`, see [Manage access](project-setup.md#manage-access). Without the admin role, packagist.org is not updated after a release.

## Status checks

The action [(📡) Verify](project-setup.md#verify) runs one job per PHP version configured in `phpVersions` of the `.github/workflows/verify.yml`:

```yaml
jobs:
  verify:
    uses: sitepark/github-project-workflow/.github/workflows/composer-verify.yml@release/1.x
    with:
      phpVersions: '["8.2","8.3","8.4"]'
```

Each job is reported as the status check `verify / Composer Verify (PHP x.y)`. Add these status checks as required status checks to the [`main`-Branch protection](project-setup.md#require-status-checks-to-pass-before-merging). If a PHP version is added to `phpVersions`, it only becomes a required status check once it is also added to the branch protection.

## Register to packagist.org

Log in to GitHub as `sitepark-bot` first, then log in to [packagist.org](https://packagist.org/){:target="\_blank"} via GitHub.

Submit the package: [https://packagist.org/packages/submit](https://packagist.org/packages/submit){:target="\_blank"}

Sync the package in the profile to add the webhook: [https://packagist.org/profile/](https://packagist.org/profile/){:target="\_blank"}

## Register to app.snyk.io

[https://app.snyk.io/](https://app.snyk.io/){:target="\_blank"}

Log in with a user who has administration rights for the GitHub organization sitepark.
Add the project.
