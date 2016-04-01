class CommentsController < ApplicationController

  before_action :authenticate_user!, only: [:create, :destroy]
  before_action :set_item, only: [:index, :create, :destroy]

  def index
    @current_user_id = current_user.present? ? current_user.id : nil
  end

  def create
    unless @item.can_show?(current_user)
      render json: { }, status: :unprocessable_entity
    end

    @comment = Comment.new(
      user_id: current_user.id,
      item_id: @item.id,
      content: params[:comment][:content]
    )

    if @comment.save
      event = Event.create(
        event_type: :comment,
        acter_id: current_user.id,
        suffered_user_id: @item.user_id,
        related_id: @item.id,
        properties: {
          comment_id: @comment.id
        }
      )
      @item.user.notification.add_unread_event(event)

      render json: json_rendered_comment
    else
      render json: {errors: @comment.errors }, status: :unprocessable_entity
    end

  end

  def destroy
    @comment = Comment.find(params[:comment_id])

    @comment.is_deleted = true

    if @comment.save
      event = Event.where(
        event_type: Event.event_types[Event::COMMENT],
        acter_id: current_user.id,
        suffered_user_id: @item.user_id,
        related_id: @item.id
      ).select{|e|
        eval(e.properties)[:comment_id] == @comment.id
      }.first

      event.update_attribute("is_deleted", true)

      render json: json_rendered_comment
    else
      render json: { }, status: :unprocessable_entity
    end
  end

  private
  def set_item
    @item = Item.find(params[:id])
  end

  def json_rendered_comment
    rendered_comment = {
      id: @comment.id,
      item_id: @comment.item_id,
      content: @comment.content,
      commented_date: @comment.created_at,
      can_delete: (@comment.user_id == (current_user.present? ? current_user.id : nil)),
      commenter: @comment.user.to_light,
      is_deleted: @comment.is_deleted
    }

    return rendered_comment
  end

end
