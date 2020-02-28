class ArticlesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  helper_method :article

  respond_to :html

  def index
    @articles = Article.all.order(id: :desc)
  end

  def new
    @article = Article.new
  end

  def edit
    article
  end

  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to articles_url, notice: 'Article was successfully created.'
    else
      render :new
    end
  end

  def update
    if article.update(article_params)
      redirect_to articles_url, notice: 'Article was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    article.destroy
    redirect_to articles_url, notice: 'Article was successfully destroyed.'
  end

  private

  def article
    @article ||= Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :summary, :image_url, :description)
  end
end
