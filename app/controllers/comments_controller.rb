class CommentsController < ApplicationController

  before_action :authenticate_user!, only: [:create, :destroy]
  before_action :set_item, only: [:create, :destroy]

  # def index
  # end

  def create
    unless @item.can_show?(current_user)
      render json: { }, status: :unprocessable_entity
    end

    comment = Comment.new(
      user_id: current_user.id,
      item_id: @item.id,
      content: params[:comment][:content]
    )

    if comment.save
      event = Event.create(
        event_type: :comment,
        acter_id: current_user.id,
        suffered_user_id: @item.user_id,
        related_id: @item.id,
        properties: {
          comment_id: comment.id
        }
      )
      @item.user.notification.add_unread_event(event)

      render json: { status: :ok , commenter: current_user.to_light}
    else
      render json: { }, status: :unprocessable_entity
    end

  end

  def destroy
    comment = Comment.find(params[:comment_id])

    comment.destroy

    if comment.destroyed?
      event = Event.where(
        event_type: Event.event_types["comment"],
        acter_id: current_user.id,
        suffered_user_id: @item.user_id,
        related_id: @item.id
      ).select{|e|
        eval(e.properties)[:comment_id] == comment.id
      }.first

      event.update_attribute("is_deleted", true)

      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

  private
  def set_item
    @item = Item.find(params[:id])
  end

end
