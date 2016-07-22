json.extract! @home_list, :id
json.partial! 'items/child_item_list', locals: {child_items: @dump_items, has_next: @has_next_item, next_page: @next_page_for_item}
