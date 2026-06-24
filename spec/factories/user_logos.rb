FactoryBot.define do
  factory :user_logo do
    user
    sequence(:url) { |n| "https://test-bucket.example.com/user_logos/#{n}.png" }
    status { :pending }
  end
end
