json.popular_tag popular_tag do |tag|
  json.tag_name tag[:tag_name]
  json.tag_id tag[:tag_id]
  json.tag_count tag[:tag_count]
  json.items tag[:item] do |i|
    json.extract! i, :id, :name, :is_list, :count
    json.thumbnail i.thumbnail
    json.tags i.tag_list
    json.favorite_count i.favorites.size
  end

end
