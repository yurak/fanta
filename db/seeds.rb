
SlotCreator.new.create_module
Seeder.new(objects_name: 'clubs').save
Seeder.new(objects_name: 'teams').save
Seeder.new(objects_name: 'positions').save
Seeder.new.teams.each do |team|
  Seeder.new(team_name: team).create_team
end


Seeder.create_tours
