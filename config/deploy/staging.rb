# cap staging deploy BRANCH=staging

role :app, %w{ubuntu@52.18.97.192}
role :web, %w{ubuntu@52.18.97.192}
role :db, %w{ubuntu@52.18.97.192}
set :ssh_options, {
  keys: %w(~/.ssh/mantrakey.pem),
  forward_agent: false,
  auth_methods: %w(publickey password)
}
