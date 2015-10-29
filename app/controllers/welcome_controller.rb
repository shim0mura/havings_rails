class WelcomeController < ApplicationController

  before_action :authenticate_user!

  def index
    @current_user = current_user
  end

  def home
    @current_user = current_user
    @timeline = following_timeline(nil, 5) if @current_user
  end

  def timeline
    @current_user = current_user
    timeline = following_timeline(params[:from]) if @current_user
    render partial: 'shared/timeline', layout: false, locals: {timeline: timeline, has_next_event: @has_next_event, is_home: true}
  end

  private
  def following_timeline(from = 0, size = User::MAX_SHOWING_EVENTS)
    timeline = []
    @current_user.following.each do |user|
      timeline.concat(user.timeline(@current_user, from))
    end
    n = timeline.size
    0.upto(n - 2) do |i|
      (n - 1).downto(i + 1) do |j|
        if timeline[j][:event_id] > timeline[j - 1][:event_id]
          timeline[j], timeline[j - 1] = timeline[j - 1], timeline[j]
        end
      end
    end
    @has_next_event = (n >= size)
    timeline.slice(0...size)
  end

end
