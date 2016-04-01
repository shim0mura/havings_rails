json.partial! 'items/item_image_list', locals: {images: @next_images, user_id: (current_user.present? ? current_user.id : nil), has_next: @has_next_image}
