module Users
  class Creator < ApplicationService
    def call
      users.each do |user_email|
        User.create(email: user_email, password: '123456', password_confirmation: '123456')
      end
    end

    private

    def users
      YAML.load_file(Rails.root.join('config/mantra/users.yml'))
    end
  end
end
