class UserController < ApplicationController

  # before_action :authenticate_user!, only:[:follow, :remove]
  before_action :set_user

  def index
    @current_user = user_signed_in? ? current_user : nil
    @user_timeline = @user.timeline
    @has_next_event = @user.has_next_event_from?(@user_timeline.last[:event_id])
  end

  def timeline
    timeline = @user.timeline(params[:from])
    pp timeline
    render partial: 'timeline', layout: false, locals: {timeline: timeline, has_next_event: @user.has_next_event_from?(timeline.last[:event_id])}
  end

  private
  def set_user
    @user = User.find(params[:user_id])
  end

end
