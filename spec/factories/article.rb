FactoryBot.define do
  factory :article do
    title { FFaker::Lorem.phrase }
    summary { FFaker::Lorem.sentence }
    description { FFaker::HTMLIpsum.body }

    article_tag

    factory :published_article do
      status { :published }
    end

    factory :article_with_image do
      image_url { FFaker::Internet.http_url }
    end

    factory :article_with_internal_image do
      internal_image_url { FFaker::Internet.http_url }
    end

    factory :article_with_both_images do
      image_url { FFaker::Internet.http_url }
      internal_image_url { FFaker::Internet.http_url }
    end
  end
end
