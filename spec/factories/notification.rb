FactoryBot.define do
  factory :notification do
    team
    notifiable factory: %i[tour]
    kind { :tour_opened }
    status { :pending }
    priority { :normal }
  end
end
