# cap staging deploy BRANCH=staging

role :app, %w{ubuntu@34.253.224.14}
role :web, %w{ubuntu@34.253.224.14}
role :db, %w{ubuntu@34.253.224.14}
set :ssh_options, {
  keys: %w(~/.ssh/mantrakey.pem),
  forward_agent: false,
  auth_methods: %w(publickey password)
}
