json.extract! @home_list, :id
json.partial! 'items/child_item_list', locals: {child_items: @next_items, has_next: @has_next_item}
