FactoryBot.define do
  factory :club_transfer_request do
    player
    new_club factory: %i[club]
    new_club_name { 'Club Name' }
    start_date { Time.zone.today }
    loan { false }
    status { :pending }
  end
end
