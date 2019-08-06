class UserCreator
  def call
    users.each do |team_name, user_email|
      user = User.create(email: user_email, password: '123456', password_confirmation: '123456')
      team = Team.find_by(name: team_name)
      team.update(user: user)
    end
  end

  private

  def users
    YAML.load_file(Rails.root.join('config', 'mantra', 'users.yml'))
  end
end
