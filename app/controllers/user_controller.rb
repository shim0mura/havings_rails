class UserController < ApplicationController

  before_action :set_user

  def index
    @current_user = user_signed_in? ? current_user : nil

    @user_timeline = @user.timeline(current_user)
    @has_next_event = @user.has_next_event_from?(@user_timeline.last[:event_id])
  end

  def timeline
    timeline = @user.timeline(current_user, params[:from])
    render partial: 'shared/timeline', layout: false, locals: {timeline: timeline, has_next_event: @user.has_next_event_from?(timeline.last[:event_id])}
  end

  private
  def set_user
    @user = User.find(params[:user_id])
  end

end
