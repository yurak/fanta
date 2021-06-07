module AuthHelper
  def login_admin
    before do
      @request.env['devise.mapping'] = Devise.mappings[:admin]
      sign_in create(:admin)
    end
  end

  def login_moderator
    before do
      @request.env['devise.mapping'] = Devise.mappings[:moderator]
      sign_in create(:moderator)
    end
  end

  def login_user
    before do
      sign_in create(:user)
    end
  end
end
