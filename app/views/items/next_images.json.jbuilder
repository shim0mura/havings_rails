json.extract! @item, :id

json.partial! 'item_image_list', locals: {images: @next_images, has_next: @has_next_image}
