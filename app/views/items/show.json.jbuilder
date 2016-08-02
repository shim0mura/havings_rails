# item data(id, name, desc, is_list, is_garbage, count, garbage_reason)
# thumbnail
# meta_data(fav, comments)favした人一覧やコメント一覧は別ページにて表示するので
# ここでは純粋に数値のみを取得
# owning user
#   => user_entity
# tag
# bredcrumb
#
# タブ内情報（追加取得用API必要）
# include items(item.to_lightにfav追加)
# image_list
# graph(count_properties)
#   => event_entity
#
# 持ち主の場合はtimer
# private設定によって見えない場合はそれ用のレスポンス

json.extract! @item, :id, :name, :description, :is_list, :is_garbage, :garbage_reason, :list_id, :count, :created_at, :updated_at
json.breadcrumb @item.breadcrumb
json.thumbnail @item.thumbnail
json.private_type Item.private_types[@item.private_type]

json.owner do
  json.extract! @item.user.to_light, :id, :name, :image
end

json.favorite_count @item.favorites.size
json.is_favorited @item.is_favorited?(current_user)
json.comment_count @item.comments.size
json.done_count @done_tasks

json.owning_item_count @item.child_items.select{|i|!i.is_garbage}.size
json.image_count @item.item_images.size

json.item_images do
  json.partial! 'item_image_list', locals: {images: @next_images, user_id: (current_user.present? ? current_user.id : nil), has_next: @has_next_image, next_page: @next_page_for_image, owner_id: @item.user_id}
end

json.tags @item.tags.map{|t|t.name}

json.partial! 'child_item_list', locals: {child_items: @next_items, has_next: @has_next_item, next_page: @next_page_for_item}

json.partial! 'timer_lists', locals: {timers: @item.timers, can_add_timer: @item.can_add_timer?}

# eventsというkeyはItem.showing_itemで使うのでここでは別のものに変えておく
# どうせクライアント側もevent_idsを利用しない
# json.count_properties JSON.parse(@item.count_properties).each{|e|e["event_ids"] = e["events"];e.delete("events")}
json.count_properties @item.showing_events
