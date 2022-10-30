RSpec.describe 'Articles' do
  describe 'GET #index' do
    before do
      get articles_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:articles)).not_to be_nil }
    it { expect(assigns(:left)).not_to be_nil }
    it { expect(assigns(:right)).not_to be_nil }
  end

  describe 'GET #show' do
    let(:article) { create(:article) }

    before do
      get article_path(article)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:article)).not_to be_nil }
    it { expect(assigns(:article)).to eq(article) }
  end

  describe 'GET #new' do
    before do
      get new_article_path
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        create_list(:article_tag, 3)
        get new_article_path
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        create_list(:article_tag, 3)
        get new_article_path
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        create_list(:article_tag, 3)
        get new_article_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to render_template(:_form) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:article)).not_to be_nil }
    end
  end

  describe 'POST #create' do
    let(:title) { FFaker::Lorem.phrase }
    let(:params) do
      {
        article: {
          title: title,
          description: FFaker::HTMLIpsum.body
        }
      }
    end

    before do
      post articles_path(params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        post articles_path(params)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        post articles_path(params)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with valid params when admin is logged in' do
      let(:article) { Article.find_by(title: title) }

      login_admin
      before do
        post articles_path(params)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }

      it 'creates article with specified title' do
        expect(article.title).to eq(title)
      end
    end

    context 'with invalid params when admin is logged in' do
      let(:title) { '' }

      login_admin
      before do
        create_list(:article_tag, 3)
        post articles_path(params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to render_template(:_form) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'GET #edit' do
    let(:article) { create(:article) }

    before do
      get edit_article_path(article)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        create_list(:article_tag, 3)
        get edit_article_path(article)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        create_list(:article_tag, 3)
        get edit_article_path(article)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        create_list(:article_tag, 3)
        get edit_article_path(article)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to render_template(:_form) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:article)).not_to be_nil }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:article) { create(:article) }
    let(:title) { FFaker::Lorem.phrase }
    let(:params) do
      {
        article: {
          title: title,
          description: FFaker::HTMLIpsum.body
        }
      }
    end

    before do
      patch article_path(article, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        patch article_path(article, params)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        patch article_path(article, params)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with valid params when admin is logged in' do
      login_admin
      before do
        patch article_path(article, params)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates article with specified title' do
        expect(article.reload.title).to eq(title)
      end
    end

    context 'with invalid params when admin is logged in' do
      let(:title) { '' }

      login_admin
      before do
        create_list(:article_tag, 3)
        patch article_path(article, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to render_template(:_form) }
      it { expect(response).to have_http_status(:ok) }

      it 'does not update article title' do
        expect(article.reload.title).not_to eq(title)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:article) { create(:article) }

    before do
      delete article_path(article)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        delete article_path(article)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        delete article_path(article)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        delete article_path(article)
      end

      it { expect(response).to redirect_to(articles_path) }
      it { expect(response).to have_http_status(:found) }

      it 'destroys article' do
        expect(Article.find_by(id: article.id)).to be_nil
      end
    end
  end
end
