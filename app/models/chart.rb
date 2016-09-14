class Chart < ActiveRecord::Base

  CHART_TYPE_ETC      = 0
  CHART_TYPE_CLOTHING = 1
  CHART_TYPE_FOOD     = 2
  CHART_TYPE_LIVING   = 3
  CHART_TYPE_HOBBY    = 4

  TAG_TYPE_CATEGORY  = 3
  TAG_TYPE_THING     = 2
  TAG_TYPE_ATTRIBUTE = 4

  # タグidからrootカテゴリ決定
  # 分類なし
  ETC_TAG_IDS = [1340]
  # 衣: ファッション、コスメ
  CLOTHING_TAG_IDS = [1, 392]
  # 食: 食品、キッチン用品
  FOOD_TAG_IDS     = [326, 769]
  # 住: 家電、家具、日用品
  LIVING_TAG_IDS   = [469, 599, 856]
  # その他: 趣味、本
  HOBBY_TAG_IDS    = [1042, 1305]

  belongs_to :user

  def self.add_item_to_total_chart(item: , count: , tag: nil)
    return unless item.present?
    return if item.is_garbage || item.is_list
    user = item.user
    chart = user.chart
    tags = (tag.present? ? tag : item.tags)

    chart_type, tag_ancestors = get_primary_category_ancestors(tags)
    chart_detail = JSON.parse(chart.chart_detail) rescue []

    p "#"*20
    pp chart_type, tag_ancestors

    type = chart_detail.detect{|e|e.has_key?("type") && e["type"] == chart_type}
    unless type.present?
      p "0"*20
      type = {}
      type["type"] = chart_type
      type["count"] = 0
      type["percentage"] = 100
      type["childs"] = []
      chart_detail << type
    end

    type["count"] = type["count"] + count

    category = type["childs"]
    tag_ancestors.each do |tag_ancestor|
      next if tag_ancestor.tag_type == TAG_TYPE_THING

      category_detail = category.detect{|e|e.has_key?("tag_id") && e["tag_id"] == tag_ancestor.id}
      unless category_detail.present?
        category_detail = {}
        category_detail["tag"] = tag_ancestor.name
        category_detail["tag_id"] = tag_ancestor.id
        category_detail["count"] = 0
        category_detail["percentage"] = 100
        category_detail["childs"] = []
        category << category_detail
      end

      category_detail["count"] = category_detail["count"] + count
      category = category_detail["childs"]

      item.classed_tag_id = tag_ancestor.id
    end

    # 分類タグの設定
    item.save!

    total_count = chart_detail.map{|e|e["count"]}.sum{|i|i.to_i}

    chart_detail.each do |detail|
      calc_percentage(detail, total_count)
    end

    chart_detail
    chart.chart_detail = chart_detail.to_json
    chart.save!
  end

  def self.delete_item_to_total_chart(item: , count: , tag: nil)
    return unless item.present?
    return if item.is_list
    user = item.user
    chart = user.chart
    tags = (tag.present? ? tag : item.tags)

    chart_type, tag_ancestors = get_primary_category_ancestors(tags)
    chart_detail = JSON.parse(chart.chart_detail) rescue []

    if chart_detail.empty?
      logger.warn("chart_detail_is_empty_for_some_reason_in_spite_of_delete_item_from_chart, chart_id: #{chart.id}, item_id: #{item.id}")
      return
    end

    p "#"*20
    pp chart_type, tag_ancestors

    type = chart_detail.detect{|e|e.has_key?("type") && e["type"] == chart_type}
    unless type.present?
      logger.warn("chart_type_is_empty_for_some_reason_in_spite_of_delete_item_from_chart, chart_type: #{chart_type}, item_id: #{item.id}, tags: #{tags.map(&:id)}")
      return
    end

    type["count"] = type["count"] - count

    if type["count"] > 0
      category = type["childs"]
      tag_ancestors.each do |tag_ancestor|
        next if tag_ancestor.tag_type == TAG_TYPE_THING

        category_detail = category.detect{|e|e.has_key?("tag_id") && e["tag_id"] == tag_ancestor.id}
        unless category_detail.present?
          logger.warn("category_detail_is_empty_for_some_reason_in_spite_of_delete_item_from_chart, chart_type: #{chart_type}, item_id: #{item.id}, tags: #{tags.map(&:id)}, tag_id: #{tag_ancestor.id}, category_ids: #{category.map{|e|e['tag_id']}}")
          break
        end

        category_detail["count"] = category_detail["count"] - count

        if category_detail["count"] > 0
          category = category_detail["childs"]
        elsif category_detail["count"] == 0
          category.delete(category_detail)
        else
          logger.warn("category_detail_count_go_negative_for_some_reason_in_spite_of_delete_item_from_chart, chart_type: #{chart_type}, item_id: #{item.id}, tags: #{tags.map(&:id)}, count: #{count}, type[count]: #{type['count']}, category_detail: #{category_detail['tag_id']}")
          category.delete(category_detail)
        end

      end
    elsif type["count"] == 0
      chart_detail.delete(type)
    else
      logger.warn("chart_type_count_go_negative_for_some_reason_in_spite_of_delete_item_from_chart, chart_type: #{chart_type}, item_id: #{item.id}, tags: #{tags.map(&:id)}, count: #{count}, type[count]: #{type['count']}")
      chart_detail.delete(type)
    end

    total_count = chart_detail.map{|e|e["count"]}.sum{|i|i.to_i}

    chart_detail.each do |detail|
      calc_percentage(detail, total_count)
    end

    chart.chart_detail = chart_detail.to_json
    chart.save!
  end

  # タグのうちの優先カテゴリを取得する
  # 引数はItem.tagsを想定
  # そのアイテムのタグが複数の優先カテゴリにまたがる場合
  # (アイテムに"服"と"酒"がつけられてるなど)
  # タグ自体の優先度と各カテゴリに属するタグの数で優先カテゴリを決定する
  def self.get_primary_category_ancestors(tags)
    uncategorized_ancestors = ActsAsTaggableOn::Tag.where(id: ETC_TAG_IDS)
    return [CHART_TYPE_ETC, uncategorized_ancestors] if tags.nil? || tags.empty?

    priority = {}
    priority[CHART_TYPE_CLOTHING] = {priority: 0, ancestors: []}
    priority[CHART_TYPE_FOOD]     = {priority: 0, ancestors: []}
    priority[CHART_TYPE_LIVING]   = {priority: 0, ancestors: []}
    priority[CHART_TYPE_HOBBY]    = {priority: 0, ancestors: []}

    tags.each do |tag|
      next unless tag.is_default_tag
      next unless tag.tag_type == TAG_TYPE_CATEGORY || tag.tag_type == TAG_TYPE_THING

      parent_tag_id = tag.parent_id
      parent_tag = tag
      tag_ancestors = [tag]

      p parent_tag_id

      while parent_tag_id != nil do
        p parent_tag_id
        parent_tag = ActsAsTaggableOn::Tag.where(id: parent_tag_id).first
        tag_ancestors.unshift(parent_tag)
        parent_tag_id = parent_tag.parent_id
      end

      p tag_ancestors.map(&:name)

      case parent_tag.id
      when *CLOTHING_TAG_IDS
        priority[CHART_TYPE_CLOTHING][:priority] = priority[CHART_TYPE_CLOTHING][:priority] + tag_ancestors.map(&:priority).sum{|i|i.to_i}
        priority[CHART_TYPE_CLOTHING][:ancestors] << tag_ancestors
      when *FOOD_TAG_IDS
        priority[CHART_TYPE_FOOD][:priority] = priority[CHART_TYPE_FOOD][:priority] + tag_ancestors.map(&:priority).sum{|i|i.to_i}
        priority[CHART_TYPE_FOOD][:ancestors] << tag_ancestors
      when *LIVING_TAG_IDS
        priority[CHART_TYPE_LIVING][:priority] = priority[CHART_TYPE_LIVING][:priority] + tag_ancestors.map(&:priority).sum{|i|i.to_i}
        priority[CHART_TYPE_LIVING][:ancestors] << tag_ancestors
      when *HOBBY_TAG_IDS
        priority[CHART_TYPE_HOBBY][:priority] = priority[CHART_TYPE_HOBBY][:priority] + tag_ancestors.map(&:priority).sum{|i|i.to_i}
        priority[CHART_TYPE_HOBBY][:ancestors] << tag_ancestors
      else
      end

    end

    chart_type = 0
    if priority.values.all?{|v| v[:priority] == 0}
      return [CHART_TYPE_ETC, uncategorized_ancestors]
    else
      chart_type = priority.sort{|(k1, v1), (k2, v2)| v2[:priority] <=> v1[:priority]}.first.first
    end

    if priority[chart_type][:ancestors].size > 1
      tag_ancestors = priority[chart_type][:ancestors].sort_by!{|p|p.map(&:priority).sum{|i|i.to_i}}.last
    else
      tag_ancestors = priority[chart_type][:ancestors].first
    end

    return [chart_type, tag_ancestors]
  end

  def self.calc_percentage(detail, total_count)
    detail["percentage"] = ((detail["count"].to_f / total_count) * 100).round(1)
    detail["childs"].each do |child|
      calc_percentage(child, total_count)
    end
  end

end
