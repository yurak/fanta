# cap staging deploy BRANCH=staging

role :app, %w{ubuntu@54.171.61.116}
role :web, %w{ubuntu@54.171.61.116}
role :db, %w{ubuntu@54.171.61.116}
set :ssh_options, {
  keys: %w(~/.ssh/mantrakey.pem),
  forward_agent: false,
  auth_methods: %w(publickey password)
}
