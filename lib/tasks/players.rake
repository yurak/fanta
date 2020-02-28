namespace :players do
  desc 'Change player name'
  task :rename, %i[old_name new_name] => :environment do |_t, args|
    player = Player.find_by(name: args[:old_name])
    player.update(name: args[:new_name])
  end
end
