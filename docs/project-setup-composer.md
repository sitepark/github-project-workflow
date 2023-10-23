# Setup for composer projects

## Manage access

In (packagist.org)[https://packagist.org/] a user `sitepark` is created. This is linked to the `sitepark-bot` user of GitLab to manage the webhooks for packagist.org. See also: [How to update packages?](https://packagist.org/about#how-to-update-packages)
To manage the webhooks for the composer projects, the `sitepark-bot` account for composer projects needs the `Admin` role.

## Register to packagist.org

Login as Sitepark-Bot (Via Github, login as Sitepark-Bot first to Github)

https://packagist.org/


Submit package https://packagist.org/packages/submit

Sync Package https://packagist.org/profile/ to add Webhook.

## Register to snyk.io

https://snyk.io/

Log in with a user who has administration rights for the Github Sitepark organization.
Add the project.