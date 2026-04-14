module Manage
  class ClubsController < BaseController
    PER_PAGE = 30

    def index
      @clubs = Club.order(id: :desc)
      @clubs = @clubs.where('name LIKE ?', "%#{params[:name]}%") if params[:name].present?
      @clubs = @clubs.page(params[:page]).per(PER_PAGE)
    end
  end
end
