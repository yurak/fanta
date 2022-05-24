FactoryBot.define do
  factory :player_request do
    association :player
    association :user

    positions { [Position.last.name] }
  end
end
