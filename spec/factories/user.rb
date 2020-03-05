FactoryBot.define do
  factory :user do
    sequence(:email) { |i| "testuser+#{i}@test.com" }
    password { 'Fanta1!' }
    password_confirmation { password }

    association :team
  end
end
