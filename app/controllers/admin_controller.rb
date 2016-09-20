class AdminController < ApplicationController

  before_filter :basic_auth

  def index
    @item = YahooCategory.find(43780)
    @items = YahooCategory.where(tagged_depth: 100, is_default_tag: true, parent_id: nil)
  end

  def tags
    @tags = ActsAsTaggableOn::Tag.where(is_default_tag: true, parent_id: nil)
  end

  def extract
    item_ids = params["item_id"]
    YahooCategory.where(id: item_ids).update_all(is_default_tag: true)
  end

  def extracted_item
    @item = YahooCategory.find(39569)
  end

  def type_item
    item_ids = params["item_id"]
    item_ids.each do |k, v|
      i = YahooCategory.where(id: k.to_i).first
      next unless i
      i.tag_type = v
      i.save
    end
  end

  def delete
    item_ids = params["item_id"]
    items = YahooCategory.where(id: item_ids)
    ids = []
    items.each do |i|
      ids.concat(i.recursive_child)
    end
    p ids
    YahooCategory.delete(ids)

  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == "havings" && "shimomura"
    end
  end
  

end
