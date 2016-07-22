json.owning_items child_items do |child_item|
  json.extract! child_item, :id, :name, :is_list, :count
  json.thumbnail child_item.thumbnail
  json.tags child_item.tags.map{|t|t.name}
  json.favorite_count child_item.favorites.size
end
json.has_next_item has_next
json.next_page_for_item next_page
