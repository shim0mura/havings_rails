json.images images do |i|
  json.id i.id
  json.url i.image_url
  json.date i.created_at
  json.added_date i.added_at
  json.memo i.memo
end

json.has_next_image has_next
