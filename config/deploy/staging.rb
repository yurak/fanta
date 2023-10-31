# cap staging deploy BRANCH=staging

role :app, %w{ubuntu@54.246.29.19}
role :web, %w{ubuntu@54.246.29.19}
role :db, %w{ubuntu@54.246.29.19}
set :ssh_options, {
  keys: %w(~/.ssh/mantrakey.pem),
  forward_agent: false,
  auth_methods: %w(publickey password)
}
