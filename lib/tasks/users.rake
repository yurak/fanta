namespace :users do
  desc 'Update user to Admin role by email'
  task :admin, [:email] => :environment do |_t, args|
    user = User.find_by(email: args[:email])
    user&.admin!
  end

  desc 'Update user to Moderator role by email'
  task :moderator, [:email] => :environment do |_t, args|
    user = User.find_by(email: args[:email])
    user&.moderator!
  end

  desc 'Search users by TG messages'
  task tg_messages_search: :environment do
    TgMessage.find_each do |message|
      next if UserProfile.find_by(tg_chat_id: message.chat_id)
      next if message.text == '/start'

      user = User.find_by(email: message.text)
      puts "#{message.text} - id: #{user.id}" if user
    end
  end
end
