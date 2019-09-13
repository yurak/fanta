namespace :tours do
  desc 'Unlock tour by number'
  task :unlock, [:number] => :environment do |_t, args|
    tour = Tour.find_by(number: args[:number].to_i)
    tour&.set_lineup!
  end
end
