json.extract! item, :id, :name, :is_list, :private_type, :count, :list_id, :description, :tags, :is_garbage, :path

if item[:owning_items] != nil && !item[:owning_items].empty?
  json.owning_items item[:owning_items] do |child|
    json.partial! 'items/recursive_item_list', locals: {item: child}
  end
else
  json.owning_items []
end
