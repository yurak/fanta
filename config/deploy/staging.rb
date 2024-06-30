# cap staging deploy BRANCH=staging

role :app, %w{ubuntu@3.252.122.206}
role :web, %w{ubuntu@3.252.122.206}
role :db, %w{ubuntu@3.252.122.206}
set :ssh_options, {
  keys: %w(~/.ssh/mantrakey.pem),
  forward_agent: false,
  auth_methods: %w(publickey password)
}
