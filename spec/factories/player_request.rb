FactoryBot.define do
  factory :player_request do
    player
    user

    positions { [Position.last.name] }
  end
end
