# Setup for composer projects

## Manage access

In [packagist.org](https://packagist.org/){:target="\_blank"} a user `sitepark` is created. This is linked to the `sitepark-bot` user of GitLab to manage the webhooks for packagist.org. See also: [How to update packages?](https://packagist.org/about#how-to-update-packages){:target="\_blank"}
To manage the webhooks for the composer projects, the `sitepark-bot` account for composer projects needs the `Admin` role.

## Register to packagist.org

Login as Sitepark-Bot (Via Github, login as Sitepark-Bot first to Github)

[https://packagist.org/](https://packagist.org/){:target="\_blank"}

Submit package [https://packagist.org/packages/submit](https://packagist.org/packages/submit){:target="\_blank"}

Sync Package [https://packagist.org/profile/](https://packagist.org/profile/){:target="\_blank"} to add Webhook.

## Register to app.snyk.io

[https://app.snyk.io/](https://app.snyk.io/){:target="\_blank"}

Log in with a user who has administration rights for the Github Sitepark organization.
Add the project.
