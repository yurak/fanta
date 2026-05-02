# cap production deploy BRANCH=staging
# cap production deploy BRANCH=manage_champions

server = "#{ENV.fetch('DEPLOY_SSH_USER')}@#{ENV.fetch('PRODUCTION_SERVER')}"
role :app, [server]
role :web, [server]
role :db,  [server]
set :ssh_options, {
  keys: [ENV.fetch('DEPLOY_SSH_KEY')],
  forward_agent: false,
  auth_methods: %w(publickey password)
}
