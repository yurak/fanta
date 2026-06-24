class UserLogosController < ApplicationController
  def create
    return redirect_back_with(alert: t('user_logos.no_file')) if params[:logo].blank?

    Teams::LogoUploader.call(user: current_user, file: params[:logo])
    redirect_back_with(notice: t('user_logos.uploaded'))
  rescue Teams::LogoUploader::InvalidFile => e
    redirect_back_with(alert: e.message)
  end

  def destroy
    logo = current_user.user_logos.kept.find(params[:id])

    if logo.in_use?
      redirect_back_with(alert: t('user_logos.in_use'))
    else
      logo.discard
      redirect_back_with(notice: t('user_logos.deleted'))
    end
  end

  private

  def redirect_back_with(**flash_options)
    redirect_back(fallback_location: user_path(current_user), **flash_options)
  end
end
