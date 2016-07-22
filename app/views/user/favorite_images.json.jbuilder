json.images @image_favorites do |f|
  json.id f.item_image.id
  json.item_id f.item_image.item_id
  json.item_name f.item.name
  json.url f.item_image.image_url
  json.date f.item_image.created_at
  json.added_date f.item_image.added_at
  json.memo f.item_image.memo
  json.image_favorite_count f.item_image.image_favorites.size
  json.is_favorited f.item_image.is_favorited?(@user_id)
  json.owner_name f.item.user.name
end

json.has_next_image @has_next_image
json.next_page_for_image @next_page_for_image
