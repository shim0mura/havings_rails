json.extract! @user, :id, :name, :description
json.image @user.thumbnail
json.count @home_list.count

json.following_count @user.following.count
json.follower_count @user.followed.count
json.dump_items_count @user.items.dump.count
json.image_favorites_count @user.image_favorites.count
json.favorites_count @user.favorites.count

json.registered_item_count @user.items.countable.count
json.registered_item_image_count @user_item_image_count

json.relation @user.get_relation_to(current_user)
json.is_following_viewer @user.already_follow?(current_user.id)

json.background_image @background_image

json.home_list do

  json.extract! @home_list, :id, :name, :description, :is_list, :is_garbage, :garbage_reason, :list_id, :count, :created_at, :updated_at
  json.item_images do
    json.partial! 'items/item_image_list', locals: {images: @next_images, user_id: (current_user.present? ? current_user.id : nil), has_next: @has_next_image, next_page: @next_page_for_image, owner_id: @user.id}
  end

  json.thumbnail @home_list.thumbnail

  # json.count_properties JSON.parse(@home_list.count_properties).each{|e|e["event_ids"] = e["events"];e.delete("events")}
  json.count_properties @home_list.showing_events(@relation)

  # json.partial! 'items/child_item_list', locals: {child_items: @next_items, has_next: @has_next_item, next_page: @next_page_for_item}

end

json.nested_item_from_home @user.item_tree(relation_to_owner: @relation).first
