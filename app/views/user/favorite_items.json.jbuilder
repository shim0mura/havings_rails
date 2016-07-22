json.owning_items @favorites do |f|
  json.extract! f.item, :id, :name, :is_list, :count
  json.thumbnail f.item.thumbnail
  json.tags f.item.tags.map{|t|t.name}
  json.favorite_count f.item.favorites.size
  json.owner do
    json.name f.item.user.name
  end
end

json.has_next_item @has_next_item
json.next_page_for_item @next_page_for_item
