[![CI](https://github.com/yurak/fanta/actions/workflows/ci.yml/badge.svg)](https://github.com/yurak/fanta/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/yurak/fanta/badge.svg?branch=master)](https://coveralls.io/github/yurak/fanta?branch=master)
[![CodeFactor](https://www.codefactor.io/repository/github/yurak/fanta/badge)](https://www.codefactor.io/repository/github/yurak/fanta)

# MANTRA FOOTBALL

This is fantasy football application.

**_Fantasy football one step closer to the real one!_**

- Create your league to play with friends
- Fight for best players at auction
- Choose the Module and fill it with the best players you have
- Score goals, receive bonuses and win the League

### Please visit

[MantraFootball application](http://mantrafootball.org/)

### Requirements

- Ruby 3.2.2
- Rails 6.1.5
- Node.js 21+
- Yarn 1.22

### Getting started

```
gem install bundler
bundle install
brew install overmind
yarn install
```

Copy the config file and fill in the required values:

```
cp config/application.example.yml config/application.yml
```

Required variables in `config/application.yml`:

| Variable | Description |
| --- | --- |
| `GMAIL_USERNAME` | Gmail address for dev mailer |
| `GMAIL_PASSWORD` | Gmail app password |
| `MAILER_FROM` | From address for outgoing emails |
| `MAILGUN_SMTP_LOGIN` | Mailgun SMTP login (production/staging) |
| `MAILGUN_SMTP_PASSWORD` | Mailgun SMTP password (production/staging) |
| `TELEGRAM_DEV_BOT_TOKEN` | Telegram bot token for dev/staging |
| `TELEGRAM_PROD_BOT_TOKEN` | Telegram bot token for production |
| `DEV_HOST` | Local machine IP for Action Cable in development |

Then set up the database:

```
rails db:setup
```

### Start & watch

```
./bin/dev
```

### Tests

Run all specs:

```
bundle exec rspec
```

Run API specs:

```
rspec --tag rswag
```

Generate swagger docs:

```
RAILS_ENV=test rails rswag
```

### Sync local database from production

Requires SSH access to the production server and Rails credentials with `db_prod` configured.

```
bin/db_pull
```

This opens an SSH tunnel to the production EC2, dumps the production PostgreSQL database, and restores it locally.

### Sync staging database from production

Requires SSH access to both production and staging servers, and Rails credentials with `db_prod` and `db_staging` configured.

```
bin/db_push_to_staging
```

This opens an SSH tunnel to the production RDS, dumps `mantra_production`, uploads it to the staging server via SCP, and restores it as `mantra_staging`.

### Telegram Bot

Set `TELEGRAM_DEV_BOT_TOKEN` in `config/application.yml`, then run in console:

```
Telegram::Bot::UpdatesPoller.start(Telegram.bot, Telegram::WebhookController)
```
