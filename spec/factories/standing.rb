FactoryBot.define do
  factory :standing do
    tournament
    season { Season.last || association(:season) }
    sequence(:position) { |i| i }
    team_name { FFaker::Company.name }
  end
end
