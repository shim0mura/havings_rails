json.array! @users do |user|
  json.extract! user.to_light, :id, :name, :description, :image
  json.count user.get_home_list.count
  json.relation user.get_relation_to(current_user)
end
