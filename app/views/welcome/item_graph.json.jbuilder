json.array! @chart_detail do |type|
  json.extract! type, 'type', 'count', 'percentage'
  json.childs type['childs'] do |category|
    json.extract! category, 'tag', 'tag_id', 'count', 'percentage'
    json.childs category['childs'], 'tag', 'tag_id', 'count', 'percentage'
  end
end
