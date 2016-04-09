class SearchController < ApplicationController

  def index
    # TODO: typeの値で検索対象切り替えできるように
    #       ユーザーとか説明の全文検索つかう
    page = params[:page].to_i rescue 1
    tag  = params[:tag]

    unless tag.present?
      render json: { }, status: :unprocessable_entity
    end

    @items = Item
      .includes(:tags, :item_images, :favorites)
      .tagged_with(tag)
      .page(page)
      .order(created_at: :desc)

    @current_page = @items.current_page
    @total_count = @items.total_count
    @has_next_page = !@items.last_page?
  end

end
