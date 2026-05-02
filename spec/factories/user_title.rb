FactoryBot.define do
  factory :user_title do
    user
    championship_number { 1 }
    season { '2024/25' }
    team_name { 'Test Team' }
  end
end
