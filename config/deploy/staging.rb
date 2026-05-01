# cap staging deploy BRANCH=staging

server = "#{ENV.fetch('DEPLOY_SSH_USER')}@#{ENV.fetch('STAGING_SERVER')}"
role :app, [server]
role :web, [server]
role :db,  [server]
set :ssh_options, {
  keys: [ENV.fetch('DEPLOY_SSH_KEY')],
  forward_agent: false,
  auth_methods: %w(publickey password)
}
