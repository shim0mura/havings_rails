class YahooCategory < ActiveRecord::Base

  APP_ID = "dj0zaiZpPWFMTVVKaW9NTjRUYiZzPWNvbnN1bWVyc2VjcmV0Jng9MjU-"
  SECRET = "710cc6cdab8d4dd7d2e06d40764c4346849c8aae"

  URL = "http://shopping.yahooapis.jp/ShoppingWebService/V1/json/categorySearch?appid="

  def self.get_category_start
    # http://shopping.yahooapis.jp/ShoppingWebService/V1/categorySearch?appid=dj0zaiZpPWFMTVVKaW9NTjRUYiZzPWNvbnN1bWVyc2VjcmV0Jng9MjU-&category_id=37644
    url = create_url(1)
    p url
    response = HTTParty.get(url)
    json_body = JSON.parse(response.body)
    first = json_body["ResultSet"]["0"]["Result"]["Categories"]
    first["Children"].each do |k, v|
      get_category(v["Id"])
    end

  end

  def self.get_category(category_id, parent_id = nil, root_category_id = nil)
    url = create_url(category_id)
    response = HTTParty.get(url)
    json_body = JSON.parse(response.body)
    cat = json_body["ResultSet"]["0"]["Result"]["Categories"] rescue nil
    unless cat
      p "$"*20
      p category_id
      return
    end

    path = cat["Current"]["Path"].map{|k, v|
      if v["_attributes"] && v["_attributes"]["depth"]
        v["_attributes"]["depth"]
      end
    }.compact

    category_name = cat["Current"]["Title"]["Short"]

    catename_size = category_name.split("、").size
    category_name.split("、").each_with_index do |name, index|
      next if name.include?("その他")

      # record = YahooCategory.find_or_create_by(category_name: name) do |r|
      dups = YahooCategory.where(category_name: name).map(&:id)
      record = YahooCategory.create(
        category_name: name,
        category_id_by_yahoo: cat["Current"]["Id"].to_i,
        url: cat["Current"]["Url"],
        parent_id: parent_id,
        is_end: (cat["Children"].size <= 0) ? true : false,
        duplicates: (dups.size > 0) ? dups.to_s : nil,
        root_category_id: root_category_id,
        depth: path.last
      )

      parent_id = record.id if index >= (catename_size - 1)
      root_category_id = record.id unless root_category_id
    end

    # pp cat["Current"]["Title"]["Short"]
    # pp "#"*20 if cat["Children"].size <= 0

    cat["Children"].each do |k, v|
      get_category(v["Id"], parent_id, root_category_id) if v["Id"]
    end
  end

  def self.create_url(category_id)
    URL + APP_ID + "&category_id=#{category_id}"
  end

  def recursive_child(pid = nil)
    unless pid
      pid = self.id
    end
    child_ids = YahooCategory.where(parent_id: pid).map(&:id)

    current_child_ids = [pid]
    child_ids.each do |c|
      current_child_ids.concat(recursive_child(c))
    end
    current_child_ids
  end

  def self.to_tagging
    YahooCategory.where(is_default_tag: true).each do |i|
      new_i = YahooCategory.new
      new_i.category_name = i.category_name
      new_i.category_id_by_yahoo = i.category_id_by_yahoo
      new_i.is_end = i.is_end
      new_i.root_category_id = i.root_category_id
      new_i.is_default_tag = i.is_default_tag
      new_i.tag_type = i.tag_type
      if i.parent_id
        new_i.parent_id = find_tag_parent(i.parent_id)
      end

      new_i.tagged_depth = 100
      new_i.save

    end
  end

  def self.find_tag_parent(parent_id)
    p = YahooCategory.where(id: parent_id).first
    if p.nil?
      return nil
    elsif p.is_default_tag
      return p.id
    else
      find_tag_parent(p.parent_id)
    end
  end

  def self.change_parent
    items = YahooCategory.where(tagged_depth: 100)
    items.each do |i|
      next unless i.parent_id
      p = YahooCategory.where(id: i.parent_id).first
      if p.nil?
        i.parent_id = nil
      else
        ppp = YahooCategory.where(category_id_by_yahoo: p.category_id_by_yahoo)
        if ppp.size > 2
          p "#"*20 
          p ppp.map(&:id)
        end
        i.parent_id = ppp.last.id
      end
      i.save
    end
  end

  def self.convert_to_tag(category, parent = nil, nest = 1)
    tag = ActsAsTaggableOn::Tag.create(
      name: category.category_name,
      tag_type: category.tag_type,
      is_default_tag: true,
      priority: (nest ? (nest * 100) : 500),
      parent_id: (parent ? parent.id : nil)
    )

    children = YahooCategory.where(parent_id: category.id, is_default_tag: true)
    children.each do |c|
      YahooCategory.convert_to_tag(c, tag, nest + 1)
    end
  end

end
