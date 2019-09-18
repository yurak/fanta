namespace :clubs do
  desc 'Update clubs code and name'
  task :update_names => :environment do
    clubs_arr = YAML.load_file(Rails.root.join('config', 'mantra', 'clubs.yml'))['clubs']
    clubs_arr.each do |name|
      c = Club.find_by(name: name[0..2].upcase)
      c.update(code: c.name, name: name)
    end
  end
end
