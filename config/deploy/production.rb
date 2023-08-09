# role :app, %w{ubuntu@ip}
# role :web, %w{ubuntu@ip}
# role :db,  %w{ubuntu@ip}
# set :ssh_options, {
#    keys: %w(path),
#    forward_agent: false,
#    auth_methods: %w(publickey password)
# }
role :app, %w{ubuntu@34.240.85.84}
role :web, %w{ubuntu@34.240.85.84}
role :db, %w{ubuntu@34.240.85.84}
set :ssh_options, {
  keys: %w(~/.ssh/mantrakey.pem),
  forward_agent: false,
  auth_methods: %w(publickey password)
}
