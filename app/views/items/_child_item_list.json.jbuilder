json.owning_items child_items do |child_item|
  json.extract! child_item, :id, :name, :is_list, :count
  json.thumbnail child_item.thumbnail
  json.tags child_item.tag_list
  json.favorite_count child_item.favorites.size
end
json.has_next_item has_next
