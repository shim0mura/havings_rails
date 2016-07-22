json.extract! @item, :id

json.partial! 'item_image_list', locals: {images: @next_images, user_id: (current_user.present? ? current_user.id : nil), has_next: @has_next_image, next_page: @next_page_for_image, owner_id: @item.user_id}
