p 'Create Modules'
SlotCreator.new.create_module

p 'Create Clubs'
Seeder.new(objects_name: 'clubs').save

p 'Create Teams'
Seeder.new(objects_name: 'teams').save

p 'Create Positions'
Seeder.new(objects_name: 'positions').save

p 'Create Players'
Seeder.new.teams.each do |team|
  Seeder.new(team_name: team).create_team
end

p 'Create Users'
UserCreator.new.call

p 'Create Tours'
CalendarCreator.new.call

p 'Create Result records'
ResultsManager.new.create
