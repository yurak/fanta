module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :refuse_bot_sign_up, only: :create

    def create
      if User.exists?(email: params[:user][:email].to_s.downcase.strip)
        @email_taken = true
        build_resource(sign_up_params)
        render :new
      else
        super
      end
    end

    protected

    def after_inactive_sign_up_path_for(resource)
      link_telegram_from_token(resource)
      users_confirmations_path(user: resource)
    end

    private

    def refuse_bot_sign_up
      detector = Signups::BotDetector.new(user_agent: request.user_agent,
                                          honeypot: params[Signups::BotDetector::HONEYPOT_FIELD])
      return unless detector.bot?

      Rails.logger.warn("[sign-up] refused from #{request.remote_ip}: #{detector.reason}")
      @bot_refused = true
      build_resource(email: params.dig(:user, :email))
      render :new, status: :unprocessable_entity
    end

    def link_telegram_from_token(user)
      token = params[:tg_token].presence
      return unless token

      chat_id = Rails.cache.read("tg_connect:#{token}")
      return unless chat_id

      profile = user.user_profile || user.create_user_profile
      profile.update(tg_chat_id: chat_id, bot_enabled: true)
      Rails.cache.delete("tg_connect:#{token}")
    end
  end
end
