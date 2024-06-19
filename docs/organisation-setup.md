# Organisation setup

## Create a CI Bot

The CI bot is necessary to be able to create a Maven release. The section [Setup a CI bot with GPG signature](https://github.com/gh-a-sample/github-actions-maven-release-sample#setup-a-ci-bot-with-gpg-signature) describes how to create the CI bot.

Important points here are

- [Setup with SSH](https://github.com/qcastel/github-actions-maven-release#setup-with-ssh)
- [Setup a GPG key](https://github.com/qcastel/github-actions-maven-release#setup-a-gpg-key)

Create [Create Personal Access-Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) with name `BOT_PAT`

After everything has been set up as described, the following Actions-Secrets should be set on the organization.

- `GPG_KEY`
- `GPG_KEY_ID`
- `SSH_PRIVATE_KEY`
- `BOT_PAT`

## Deploy Maven snapshot artifacts to the sitepark Maven repository

Snapshots are published in the Maven repository of Sitepark. The following action secrets must be set for this:

```
MVN_REPO_SNAPSHOT_SERVER_ID=sitepark
MVN_REPO_SNAPSHOT_SERVER_USERNAME=[USERNAME]
MVN_REPO_SNAPSHOT_SERVER_PASSWORD=[PASSWORD]
MVN_REPO_SNAPSHOT_SERVER_URL=https://nexus.sitepark.com/nexus/content/repositories/snapshots
```

## Deploy Maven release artifacts to the central Maven repository

The following pages describe how to register an account.

- https://central.sonatype.org/register/central-portal/

A token must then be generated:

- https://central.sonatype.org/publish/generate-portal-token/

Once the token has been created, the following action secrets must be set:

```
MVN_REPO_RELEASE_SERVER_ID=central
MVN_REPO_RELEASE_SERVER_USERNAME=[TOKEN USERNAME]
MVN_REPO_RELEASE_SERVER_PASSWORD=[TOKEN]
```

## Verify Settings

When all points are executed, the organization should contain the following settings:

### Actions secrets

![GitHub release draft](assets/images/github-organisation-setup-secrets.png)

## Integrate Codecov GitHub App

For a good integration of the code coverage test, the Codecov GitHub app is set up. See https://github.com/marketplace/codecov

## Integarate Snyk GitHub App

To check the dependencies for vulnerabilities, the Snyk GitHub app is integrated. See https://github.com/marketplace/snyk
