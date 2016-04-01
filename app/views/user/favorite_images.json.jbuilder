json.images @favorite_images do |i|
  json.id i.id
  json.item_id i.item_id
  json.url i.image_url
  json.date i.created_at
  json.added_date i.added_at
  json.memo i.memo
  json.image_favorite_count i.image_favorites.size
  json.is_favorited i.is_favorited?(@user_id)
  json.owner_name i.item.user.name
end

json.has_next_image @has_next_image
json.last_favorite_id @last_favorite_id
