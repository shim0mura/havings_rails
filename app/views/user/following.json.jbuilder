json.array! @users do |user|
  json.id          user[:id]
  json.name        user[:name]
  json.description user[:description]
  json.image       user[:image]
  json.count       user[:total_item_count]
  json.relation    user[:relation]
end
