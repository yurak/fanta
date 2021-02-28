FactoryBot.define do
  factory :article do
    title { FFaker::Lorem.phrase }
    summary { FFaker::Lorem.sentence }
    description { FFaker::HTMLIpsum.body }

    association :article_tag

    factory :published_article do
      status { :published }
    end

    trait :with_image do
      image_url { FFaker::Internet.http_url }
    end

    trait :with_internal_image do
      internal_image_url { FFaker::Internet.http_url }
    end
  end
end
