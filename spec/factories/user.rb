FactoryBot.define do
  factory :user do
    name { FFaker::Name.first_name[0...15] }
    email { FFaker::Internet.safe_email[0...50] }
    password { FFaker::Internet.password }
    password_confirmation { password }
    role { :customer }

    factory :admin do
      role { :admin }
    end

    factory :moderator do
      role { :moderator }
    end
  end
end
