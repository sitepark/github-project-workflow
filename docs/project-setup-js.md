# Setup for JS projects

See [github-js-release-test](https://github.com/sitepark/github-js-release-test){:target="\_blank"} as an example project.

Add the files in [`.github/workflows`](https://github.com/sitepark/github-js-release-test/tree/main/.github/workflows) to the new project.

The project must contain the following scripts in the `package.json`:

```json
{
  "scripts": {
    "test": "your-test-command",
    "verify": "your-test-command",
    "build": "your-build-command"
  }
}
```

Optinally, a `format:package-json` script can be added to format the `package.json`. This is used for the release process when the version is reset.

In order for unit test and code coverage results to be processed by GitHub, it is necessary that the unit tests are output in the `junit` format in the `reports/junit-report.xml` file and the code coverage in the `cobertura` format in the `reports/coverage` directory.

Example configuration for `vite.config.ts`

```ts
import { defineConfig } from "vite";

export default defineConfig({
  test: {
    // ...
    reporters: ["junit"],
    outputFile: {
      junit: "./reports/junit-report.xml",
    },
    coverage: {
      // ...
      reporter: [/* ... , */ "cobertura"],
      reportsDirectory: "./reports/coverage",
    },
  },
});
```

The `reports` directory should also be added to the `.gitignore`.

The releases are published for the standard away with `pnpm publish`.

It is important that no `publishConfig` is defined in the `package.json`, as this is controlled via the pipeline.

The release process and other functions of the branching model are provided by the script `js-project`.

See: https://github.com/sitepark/js-project

## Register to www.npmjs.com

An account with access to the Sitepark organization is required.

Follow the instructions from [_Trusted publishing for npm packages_](https://docs.npmjs.com/trusted-publishers){:target="\_blank"}

The project [setup-npm-trusted-publish](https://github.com/azu/setup-npm-trusted-publish){:target="\_blank"} can help to create an initial project in npm.com for the new project so that it can then be configured for OIDC.

## Register to app.snyk.io

[https://app.snyk.io/](https://app.snyk.io/){:target="\_blank"}

Log in with a user who has administration rights for the Github Sitepark organization.
Add the project.
