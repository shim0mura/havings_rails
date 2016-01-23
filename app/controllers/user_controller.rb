class UserController < ApplicationController

  before_action :set_user, only: [:index, :timeline, :following, :followers]
  before_action :authenticate_user!, only: [:list_tree]

  def index
    @current_user = user_signed_in? ? current_user : nil

    @user_timeline = @user.timeline(current_user)
    @has_next_event = @user.has_next_event_from?(@user_timeline.last[:event_id])
  end

  def timeline
    timeline = @user.timeline(current_user, params[:from])
    render partial: 'shared/timeline', layout: false, locals: {timeline: timeline, has_next_event: @user.has_next_event_from?(timeline.last[:event_id])}
  end

  def list_tree
  end

  def following
    @users = get_users(@user.following, current_user)
    @heading_text = "フォローしているユーザー"
  end

  def followers
    @users = get_users(@user.followed, current_user)
    @heading_text = "フォロワー"
    render 'following'
  end

  private
  def set_user
    @user = User.find(params[:user_id])
  end

  def get_users(users, current_user)
    users.map do |user|
      home_list = user.get_home_list
      light_user = user.to_light
      light_user[:total_item_count] = home_list.count
      if current_user
        light_user[:is_following] = current_user.already_follow?(user.id)
      else
        light_user[:is_following] = false
      end
      light_user
    end
  end

end
