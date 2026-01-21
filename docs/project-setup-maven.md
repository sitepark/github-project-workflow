# Setup for maven projects

See [github-maven-release-test](https://github.com/sitepark/github-maven-release-test){:target="\_blank"} as an example project.

Maven projects are initially deployed to the staging area of the [OSS Repository](https://s01.oss.sonatype.org/){:target="\_blank"} with the release process.
See also: [Publish Guide](https://central.sonatype.org/publish/publish-guide/){:target="\_blank"}

From there, they can be transferred to the central maven repository and finally released. Here some rules are checked. To comply with all rules the `pom.xml` must contain the following:

`<url>`- A URL for the project must be specified. This can be the URL to the github project.

`<developers><developer>` - At least one development must be specified.

The artifacts must be signed.
Everything is already prepared for this in the release action and also the pgp keys are stored. Nevertheless the following must still be entered in the `pom.xml`:

```xml
<project ...>

    <properties>
        <gpg.skip>true</gpg.skip>
    <properties>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-gpg-plugin</artifactId>
                <version>3.0.1</version>
                <executions>
                    <execution>
                        <id>sign-artifacts</id>
                        <phase>verify</phase>
                        <goals>
                            <goal>sign</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        <plugins>
    </build>
</project>
```

Furthermore the following plugins should be configured as follows:

```xml
<project ...>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-source-plugin</artifactId>
                <version>3.2.0</version>
                <executions>
                    <execution>
                        <id>attach-sources</id>
                        <goals>
                            <goal>jar-no-fork</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-javadoc-plugin</artifactId>
                <version>3.4.0</version>
                <executions>
                    <execution>
                        <id>attach-javadocs</id>
                        <goals>
                            <goal>jar</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <artifactId>maven-release-plugin</artifactId>
                <version>3.0.0</version>
                <configuration>
                    <scmCommentPrefix>ci(release): </scmCommentPrefix>
                    <tagNameFormat>@{project.version}</tagNameFormat>
                </configuration>
            </plugin>
        <plugins>
    </build>
</project>
```

## Register to app.snyk.io

[https://app.snyk.io/](https://app.snyk.io/){:target="\_blank"}

Log in with a user who has administration rights for the Github Sitepark organization.
Add the project.

## GitHub Actions

The following GitHub Actions are available for Maven projects. The corresponding workflow files can be found here: [GitHub Workflows for Maven Projects](https://github.com/sitepark/github-project-workflow/tree/main/.github/workflows){:target="\_blank"}
