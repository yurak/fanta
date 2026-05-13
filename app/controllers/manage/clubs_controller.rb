module Manage
  class ClubsController < BaseController
    def index
      @clubs = Club.includes(:tournament).order(id: :desc)
      @clubs = @clubs.where('name LIKE ?', "%#{params[:name]}%") if params[:name].present?
      @clubs = @clubs.page(params[:page]).per(PER_PAGE)
    end
  end
end
