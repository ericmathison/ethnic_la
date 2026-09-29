# Ethnic LA

Facilitating the discovery of ethnic groups in Los Angeles by making data about languages, cultures, and their location more accessible. We hope to promote cultural understanding through enabling more cross-cultural interactions.

## Running Tests

`rails test:all`

## Deploying

The app is deployed with [Kamal](https://kamal-deploy.org) to the server in `config/deploy.yml`.
The image is built locally and pushed to the server over SSH, so no registry account is needed.

Requirements: Docker running locally, SSH access to the server as root, and `config/master.key`
(it decrypts the credentials, which include the database password).

```
bin/kamal setup   # first deploy: boots Postgres, kamal-proxy, and the app
bin/kamal deploy  # subsequent deploys
```

Useful aliases: `bin/kamal console`, `bin/kamal logs`, `bin/kamal dbc`.
