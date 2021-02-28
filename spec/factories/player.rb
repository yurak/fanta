FactoryBot.define do
  factory :player do
    sequence(:name) { |i| "#{FFaker::Name.last_name}#{i}" }
    first_name { FFaker::Name.first_name }
    association :club

    trait :with_pos_por do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'Por'))
      end
    end

    trait :with_pos_dc do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'Dc'))
      end
    end

    trait :with_pos_c do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'C'))
      end
    end

    trait :with_pos_a do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'A'))
      end
    end
  end
end
