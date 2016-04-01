json.items @favorite_items do |i|
  json.extract! i, :id, :name, :is_list, :count
  json.thumbnail i.thumbnail
  json.tags i.tag_list
  json.favorite_count i.favorites.size
  json.owner do
    json.name i.user.name
  end
end

json.has_next_item @has_next_item
json.last_favorite_id @last_favorite_id
