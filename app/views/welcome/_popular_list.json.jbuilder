json.popular_list popular_list do |i|
  json.extract! i, :id, :name, :is_list, :count
  json.thumbnail i.thumbnail
  json.tags i.tag_list
  json.favorite_count i.favorites.size
end
