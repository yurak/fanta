FactoryBot.define do
  factory :tournament do
    sequence(:name) { |i| "name#{i}" }
    sequence(:code) { |i| "code#{i}" }

    trait :serie_a do
      code { 'serie_a' }
    end
  end
end
