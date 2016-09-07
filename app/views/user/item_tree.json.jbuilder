json.extract! @item_tree, :id, :name, :is_list, :private_type, :count, :list_id, :description, :tags, :is_garbage, :path

if @item_tree[:owning_items] != nil && !@item_tree[:owning_items].empty?
  json.owning_items @item_tree[:owning_items] do |child|
    json.partial! 'items/recursive_item_list', locals: {item: child}
  end
end
