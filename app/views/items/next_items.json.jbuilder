json.extract! @item, :id

json.partial! 'child_item_list', locals: {child_items: @next_items, has_next: @has_next_item, next_page: @next_page_for_item}
