json.array! @item.comments do |comment|
  json.extract! comment, :id, :item_id, :content 
  json.commented_date comment.created_at
  json.can_delete @current_user_id == comment.user_id
  json.commenter do
    json.extract! comment.user.to_light, :id, :name, :image
  end
end
