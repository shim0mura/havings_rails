json.items @items do |i|
  json.extract! i, :id, :name, :is_list, :count
  json.thumbnail i.thumbnail
  json.tags i.tag_list
  json.favorite_count i.favorites.size
  # json.owner do
  #   json.name i.user.name
  # end
end

json.current_page @current_page
json.total_count @total_count
json.has_next_page @has_next_page
