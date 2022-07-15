FactoryBot.define do
  factory :user do
    name { FFaker::Name.first_name[0...15] }
    email { FFaker::Internet.safe_email[0...50] }
    password { FFaker::Internet.password }
    password_confirmation { password }
    status { :configured }
    confirmed_at { DateTime.now }
    confirmation_sent_at { DateTime.now }
    role { :customer }

    factory :admin do
      role { :admin }
    end

    factory :moderator do
      role { :moderator }
    end

    trait :with_profile do
      after(:create) do |user|
        create(:user_profile, user: user)
      end
    end
  end
end
