json.images images do |i|
  json.id i.id
  json.item_id i.item_id
  json.item_name i.item.name
  json.url i.image_url
  json.date i.created_at
  json.added_date i.added_at
  json.memo i.memo
  json.image_favorite_count i.image_favorites.size
  json.is_favorited i.is_favorited?(user_id)
  json.user_id owner_id
end

json.has_next_image has_next
json.next_page_for_image next_page
