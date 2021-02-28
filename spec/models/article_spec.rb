RSpec.describe Article, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:article_tag).optional }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :title }
    it { is_expected.to validate_presence_of :description }

    it { is_expected.to define_enum_for(:status).with_values(%i[initial published archived]) }

    it { is_expected.not_to allow_value('bad/path/to/file').for(:image_url) }
    it { is_expected.to allow_value('https://example.com/path/to/file').for(:image_url) }
  end

  describe '#image' do
    context 'without image url' do
      let(:article) { create(:article) }

      it 'returns default image path' do
        expect(article.image).to eq('article1.png')
      end
    end

    context 'with image url' do
      let(:article) { create(:article, :with_image) }

      it 'returns image path' do
        expect(article.image).to eq(article.image_url)
      end
    end
  end

  describe '#internal_image' do
    context 'without internal image and image' do
      let(:article) { create(:article) }

      it 'returns default image path' do
        expect(article.internal_image).to eq('article1.png')
      end
    end

    context 'without internal image, with image_url' do
      let(:article) { create(:article, :with_image) }

      it 'returns image path' do
        expect(article.internal_image).to eq(article.image_url)
      end
    end

    context 'with internal image' do
      let(:article) { create(:article, :with_internal_image) }

      it 'returns internal image path' do
        expect(article.internal_image).to eq(article.internal_image_url)
      end
    end
  end

  describe '#related_articles' do
    let(:article) { create(:article) }

    context 'when there are no other articles' do
      it 'returns empty array' do
        expect(article.related_articles).to eq([])
      end
    end

    context 'when there are other published articles with same tag' do
      it 'returns 2 articles' do
        create_list(:published_article, 3, article_tag_id: article.article_tag_id)

        expect(article.related_articles.count).to eq(2)
      end

      it 'returns article with same tag' do
        create_list(:published_article, 3, article_tag_id: article.article_tag_id)

        expect(article.related_articles.last.article_tag).to eq(article.article_tag)
      end
    end

    context 'when there are other published articles with another tag' do
      it 'returns 2 articles' do
        create_list(:published_article, 3)

        expect(article.related_articles.count).to eq(2)
      end
    end
  end
end
