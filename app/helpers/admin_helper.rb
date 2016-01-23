module AdminHelper

  def recursive_child_items(item)
    html = ""

    c = check_box_tag("item_id[]", item.id, false, id: "item_id_" + item.id.to_s)
    la = label_tag("item_id_"+item.id.to_s, item.depth.to_s + ". " + item.category_name)

    children = ""
    child_item = YahooCategory.where(parent_id: item.id)
    child_item.each do |i|
      children = children.html_safe + recursive_child_items(i)
    end
    children = content_tag(:ul, children) unless children.empty?
    current_html = content_tag(:li, c + la + children)

  end

  def recursive_extracted_item(item)
    html = ""

    aaa = ""
    if item.is_default_tag
      ra = label_tag("item_id[#{item.id}]", "type A", for: "item_id_#{item.id}_0")
      ra = ra + radio_button_tag("item_id[#{item.id}]", 0, false)

      rb = label_tag("item_id[#{item.id}]", "type B" , for: "item_id_#{item.id}_1")
      rb = rb + radio_button_tag("item_id[#{item.id}]", 1, false)

      rc = label_tag("item_id[#{item.id}]", "type C" , for: "item_id_#{item.id}_2")
      rc = rc + radio_button_tag("item_id[#{item.id}]", 2, true)

      rd = label_tag("item_id[#{item.id}]", "type D" , for: "item_id_#{item.id}_3")
      rd = rd + radio_button_tag("item_id[#{item.id}]", 3, false)

      re = label_tag("item_id[#{item.id}]", "type E" , for: "item_id_#{item.id}_4")
      re = re + radio_button_tag("item_id[#{item.id}]", 4, false)

      rf = label_tag("item_id[#{item.id}]", "type F" , for: "item_id_#{item.id}_5")
      rf = rf + radio_button_tag("item_id[#{item.id}]", 5, false)

      aaa = item.depth.to_s + ". id:#{item.id}, " + item.category_name + " "+ ra + "　"+ rb +"　"+ rc +"　"+ rd +"　"+ re + "　" + rf

      if item.duplicates
        dups = YahooCategory.where(id: JSON.parse(item.duplicates))
        dups_str = dups.map{|d|
          p = YahooCategory.where(id: d.parent_id).first.category_name rescue ""
          rp = YahooCategory.where(id: d.root_category_id).first.category_name rescue ""
          # d.id.to_s + ", " + d.parent_id.to_s + "," + rp + " > " + p
          rp + " > " + p
        }.join(",")
        aaa = aaa + " " + dups_str
      end

    end

    aaa = aaa.html_safe

    children = ""
    child_item = YahooCategory.where(parent_id: item.id)
    child_item.each do |i|
      children = children.html_safe + recursive_extracted_item(i)
    end
    children = content_tag(:ul, children) unless children.empty?
    # current_html = content_tag(:li, c + la + children)
    current_html = content_tag(:li, aaa + children).html_safe

  end

  def recursive_child_items_for_tag(item)
    html = ""
    # return "" if item.tag_type == 4 
    return "" if item.tag_type == 4 || item.tag_type == 2

    c = check_box_tag("item_id[]", item.id, false, id: "item_id_" + item.id.to_s)
    type = ""
    la = label_tag("item_id_"+item.id.to_s, item.tag_type.to_s + ". #{item.id}. " + item.category_name)

    children = ""
    child_item = YahooCategory.where(parent_id: item.id, is_default_tag: true)
    child_item.each do |i|
      children = children.html_safe + recursive_child_items_for_tag(i)
    end
    children = content_tag(:ul, children) unless children.empty?
    current_html = content_tag(:li, c + la + children)

  end

  def recursive_child_tag(item)
    html = ""
    return "" if item.tag_type == 4 
    # return "" if item.tag_type == 4 || item.tag_type == 2

    c = check_box_tag("item_id[]", item.id, false, id: "item_id_" + item.id.to_s)
    type = ""
    la = label_tag("item_id_"+item.id.to_s, item.tag_type.to_s + ". #{item.id}. " + item.name)

    children = ""
    child_item = ActsAsTaggableOn::Tag.where(parent_id: item.id, is_default_tag: true)
    child_item.each do |i|
      children = children.html_safe + recursive_child_tag(i)
    end
    children = content_tag(:ul, children) unless children.empty?
    current_html = content_tag(:li, c + la + children)

  end

end
