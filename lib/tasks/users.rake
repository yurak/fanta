namespace :users do
  desc 'Update user to Admin role by email'
  task :admin, [:email] => :environment do |_t, args|
    user = User.find_by(email: args[:email])
    user&.admin!
  end
end
