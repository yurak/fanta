class Seeder
  attr_reader :objects_name, :team, :team_name

  def initialize(objects_name: 'clubs', team_name: 'lol')
    @team_name = team_name

    @team = Team.find_by(name: team_name)
    @objects_name = objects_name
  end

  def self.create_tours
    (1..35).to_a.each do |number|
      Tour.create(number: number)
    end
  end

  def path
    Rails.root.join('config', 'mantra', "#{objects_name}.yml")
  end

  def team_path
    Rails.root.join('config', 'teams', "#{team_name}.yml")
  end

  def teams
    YAML.load_file(Rails.root.join('config', 'mantra', 'teams.yml'))['teams']
  end

  def create_team
    YAML.load_file(team_path)['players'].each do |player_name, v|
      club = Club.find_by(name: v[1]['club'])
      player = Player.new(name: player_name, team: team, club_id: club.id)
      player.positions << Position.where(name: v[0]['position'])
      player.save
    end

    team.players
  end

  def load
    raise 'File does not exist' unless File.exist?(path)

    YAML.load_file(path)
  end

  def save
    load[objects_name].each do |object|
      object = object[0..2].upcase if objects_name == 'clubs'
      objects_name.titleize.singularize.constantize.create(name: object)
    end
  end
end
