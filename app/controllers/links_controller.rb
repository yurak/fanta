class LinksController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  helper_method :link, :league

  respond_to :html

  def index
    @links = Link.all
  end

  def new
    @link = Link.new
  end

  def edit
    link
  end

  def create
    @link = Link.new(link_params)
    if @link.save
      redirect_to league_links_path(league), notice: 'Link was successfully created.'
    else
      render :new
    end
  end

  def update
    if link.update(link_params)
      redirect_to league_links_path(league), notice: 'Link was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    link.destroy
    redirect_to league_links_path(league), notice: 'Link was successfully destroyed.'
  end

  private

  def link
    @link ||= Link.find(params[:id])
  end

  def link_params
    params.require(:link).permit(:name, :url, :description)
  end

  def league
    @league ||= League.find(params[:league_id])
  end
end
