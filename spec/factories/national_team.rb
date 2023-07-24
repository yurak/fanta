FactoryBot.define do
  factory :national_team do
    sequence(:code) { |i| "nt#{i}" }
    sequence(:name) { |i| "#{FFaker::Address.country}#{i}" }

    tournament
  end
end
