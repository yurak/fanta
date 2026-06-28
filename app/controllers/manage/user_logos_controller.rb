module Manage
  class UserLogosController < Manage::BaseController
    TABS = %w[pending approved rejected archived].freeze

    def index
      @tab = TABS.include?(params[:tab]) ? params[:tab] : TABS.first
      @user_logos = logos_for_tab
    end

    def approve
      moderate(:approved, 'manage.user_logos.approved')
    end

    def reject
      moderate(:rejected, 'manage.user_logos.rejected')
    end

    private

    def moderate(status, notice_key)
      return redirect_to manage_user_logos_path(tab: 'pending'), alert: t('manage.user_logos.already_moderated') unless user_logo.pending?

      user_logo.update!(status: status)
      TelegramBot::LogoNotifier.call(user_logo)
      redirect_to manage_user_logos_path(tab: 'pending'), notice: t(notice_key)
    end

    def logos_for_tab
      scope = @tab == 'archived' ? UserLogo.discarded : UserLogo.kept.where(status: @tab)
      scope.includes(user: :user_profile).recent.page(params[:page]).per(PER_PAGE)
    end

    def user_logo
      @user_logo ||= UserLogo.find(params.expect(:id))
    end
  end
end
