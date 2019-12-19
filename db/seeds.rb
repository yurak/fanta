p 'Create Modules'
SlotCreator.call

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
UserCreator.call

p 'Create Tours'
CalendarCreator.call

p 'Create Result records'
ResultsManager.new.create
