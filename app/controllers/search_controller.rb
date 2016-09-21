class SearchController < ApplicationController

  def tag
    page = params[:page].to_i rescue 1
    tag  = params[:tag]

    unless tag.present?
      render json: { }, status: :unprocessable_entity
      return
    end

    @items = Item
      .includes(:tags, :item_images, :favorites)
      .where(private_type: 0)
      .tagged_with(tag)
      .page(page)
      .order(created_at: :desc)
    # TODO: 閲覧権限設定

    @tag = tag
    @current_page = @items.current_page
    @total_count = @items.total_count
    @has_next_page = !@items.last_page?

  end

  def user
    page = params[:page].to_i rescue 1
    name = params[:name]

    unless name.present?
      render json: { }, status: :unprocessable_entity
    end

    arel_name = SocialProfile.arel_table[:name]
    arel_nickname = SocialProfile.arel_table[:nickname]
    social_profiles = SocialProfile
      .where(arel_name.matches("%#{name}%")
      .or(arel_nickname.matches("%#{name}%")))

    @users = User.where(id: social_profiles.map{|s|s.user.id})
  end

  private
  def tag_params
  end

end
