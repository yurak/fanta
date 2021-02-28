FactoryBot.define do
  factory :tournament do
    sequence(:name) { |i| "name#{i}" }
    sequence(:code) { |i| "code#{i}" }
  end
end
