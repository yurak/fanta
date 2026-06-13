FactoryBot.define do
  factory :club_transfer do
    player
    old_club factory: %i[club]
    new_club factory: %i[club]
    new_club_name { 'Club Name' }
    start_date { Time.zone.today }
    loan { false }
  end
end
