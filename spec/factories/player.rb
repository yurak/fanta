FactoryBot.define do
  factory :player do
    sequence(:name) { |i| "#{FFaker::Name.last_name}#{i}" }
    first_name { FFaker::Name.first_name }
    association :club

    trait :with_team do
      after(:create) do |player|
        create(:team, players: [player])
        player.reload
      end
    end

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

    trait :with_pos_e do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'E'))
      end
    end

    trait :with_pos_c do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'C'))
      end
    end

    trait :with_pos_m do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'M'))
      end
    end

    trait :with_pos_w do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'W'))
      end
    end

    trait :with_pos_a do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'A'))
      end
    end

    trait :with_pos_pc do
      after(:create) do |player|
        create(:player_position, player: player, position: Position.find_by(name: 'Pc'))
      end
    end
  end
end
