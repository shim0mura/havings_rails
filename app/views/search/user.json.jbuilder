json.users @users do |u|
  json.extract! u, :id, :name, :description, :thumbnail
  json.count u.get_home_list.count rescue 0
  json.relation u.get_relation_to(current_user)
end
