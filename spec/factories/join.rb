FactoryBot.define do
  factory :join do
    user
    tournament
    team

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
