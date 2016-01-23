# == Schema Information
#
# Table name: items
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  description      :text(65535)
#  is_list          :boolean          default(FALSE), not null
#  is_garbage       :boolean          default(FALSE), not null
#  count            :integer          default(1), not null
#  garbage_reason   :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer          not null
#  list_id          :integer
#  private_type     :integer          default(0), not null
#  is_deleted       :boolean          default(FALSE), not null
#  count_properties :text(65535)
#

class Item < ActiveRecord::Base

  ITEM_EVENTS = 20
  SHOWING_ITEM = 10

  include EnumType

  acts_as_taggable

  enum private_type: %i(global follower friends secret)

  belongs_to :user
  has_many :item_images

  has_many :favorites

  has_many :comments

  belongs_to :list, :class_name => "Item"
  has_many :child_items, :foreign_key => "list_id", :class_name => "Item"

  has_many :timers, :foreign_key => "list_id"

  accepts_nested_attributes_for :item_images

  validates :name, presence: true
  validate :is_not_self_list

  default_scope -> { where(is_deleted: false) }

  scope :as_list, -> { where(is_list: true) }

  scope :countable, -> { where(is_garbage: false) }

  # before_create :set_default_value

  def set_default_value
    self.is_garbage = false if self.is_garbage.nil?
  end

  def is_not_self_list
    if self.list_id && self.id == self.list_id
      errors.add(:list_id, "can't specify self id as list_id")
    end
  end

  def events(from = 0, limit = ITEM_EVENTS)
    # TODO: グラフ用のshowing_eventsと一緒にしたい
    event_type = Event.event_types.select{|type|
      ["create_list", "create_item", "add_image", "dump"].include?(type)
    }.values

    if from != 0
      from_option = Event.arel_table[:id].lt(from)
      e = Event.where(from_option)
    else 
      e = Event
    end

    e
      .where(
        event_type: event_type,
        related_id: self.id,
        is_deleted: false
      )
      .order("id DESC")
      .limit(limit)
  end

  def has_next_event_from?(from)
    events(from).size > 0
  end

  def next_items(user = nil, from = 0, limit = SHOWING_ITEM)
    if from != 0
      from_option = Item.arel_table[:id].lt(from)
      i = Item.where(from_option)
    else 
      i = Item
    end

    relation_to_owner = get_relation_to_owner(user)

    i
      .where(
        list_id: self.id
      )
      .where("private_type <= ?", relation_to_owner)
      .order("id DESC")
      .limit(limit)
  end

  def has_next_item_from?(user, from)
    next_items(user, from).size > 0
  end

  def next_images(from = 0, limit = SHOWING_ITEM)
    image = ItemImage.where(id: from).first if from != 0
    if image
      from_time = image.created_at
    else 
      from_time = Time.now
    end

    ItemImage.where(item_id: self.id)
      .where("created_at < ?", from_time)
      .order("created_at DESC")
      .limit(limit)
  end

  def has_next_images_from?(from)
    next_images(from).size > 0
  end

  def is_already_listed_in?(list_id)
    lists.any? do |l|
      list_id == l.id
    end
  end

  def is_favorited?(user_id)
    Favorite.exists?(
      user_id: user_id,
      item_id: self.id
    )
  end

  def dump_recursive
    self.is_garbage = true
    dump_events = self.child_items.countable.map do |c|
      e = c.dump_recursive
    end

    dump_event = Event.create(
      event_type: :dump,
      acter_id: self.user_id,
      related_id: self.list_id,
      properties: {
        item_id: self.id
      }
    )

    change_count(0, dump_event)

    return dump_event
  end

  def delete_recursive
    self.is_deleted = true
    self.child_items.countable.each do |c|
      c.delete_recursive
    end
    self.save
  end

  def get_item_related_event
    list_event = Event.where(
      acter_id: self.user_id,
      related_id: self.list_id,
      event_type: Event.item_related_event_types
    )
    list_events = []
    list_event.each do |event|
      next unless event.properties
      item_id = eval(event.properties)[:item_id] rescue nil
      list_events.push(event.id) if item_id == self.id
    end

    item_events = Event.where(
      acter_id: self.user_id,
      related_id: self.id,
      event_type: Event.item_related_event_types
    ).collect{|e|e.id}

    item_events.concat(list_events)
    return item_events
  end

  def get_event_recursive
    item_events = get_item_related_event

    child_items.each do |c|
      # NOTE: item_eventsは参照型なのでevent_idがダブることがある
      # 本当はmarshalで渡したほうがいいけど、面倒なのでuniqで対処
      item_events.concat(c.get_event_recursive)
    end

    return item_events.uniq
  end

  def change_count(count_diff = 0, event = nil, current_list = nil)
    count_diff = 0 unless count_diff.present?
    parent_list = self.list
    # return unless parent_list

    properties = self.count_properties ? JSON.parse(self.count_properties) : []
    latest_date = properties.present? ? Date.parse(properties.last["date"]) : nil

    if latest_date && (latest_date == Date.today)
      hash = properties.pop
      hash["date"] = latest_date
    else
      hash = {}
      hash["date"] = Date.today
      hash["events"] = []
      hash["count"] = 0
    end

    hash["count"] = self.user.item_tree(nil, self.id).first[:count] + count_diff rescue count_diff

    hash["events"] << event.id if event.present?
    properties << hash

    self.count_properties = properties.to_json
    self.count = hash["count"].to_i
    self.save

    if parent_list && !current_list
      if event.present? && event.related_id == parent_list.id
        parent_list.change_count(count_diff, event)
      else
        parent_list.change_count(count_diff)
      end
      # if self.is_list
      #   parent_list.change_count(count_diff) unless current_list
      # else
      #   parent_list.change_count(count_diff, event) unless current_list
      # end
    end
  end

  def delete_image_event_evidence_for_graph(item_image_ids)
    properties = count_properties ? JSON.parse(count_properties) : []
    return [] if properties.empty?

    events = Event.where(
      event_type: Event.event_types["add_image"],
      acter_id: self.user_id,
      related_id: self.id
    )

    hash = {}
    
    events.each do |e|
      item_image_id = eval(e.properties)[:item_image_id]
      if item_image_ids.include?(item_image_id)
        hash[e.id] = item_image_id
      end
    end
    pp hash

    deleted_events = []

    # 元々add_imageしかイベントがなかったのに
    # そのadd_imageが消された場合、その日は何もイベントが起きなかったことになる
    # なので、その日の値をpropから削除する
    deleting_props = []

    properties.each do |prop|
      prop["events"].delete_if do |e|
        result = hash.has_key?(e)
        deleted_events.push(e) if result
        if result && prop["events"].select{|a|a != e}.empty?
          deleting_props << prop["date"] 
        end
        result
      end
      pp prop
    end
    pp deleting_props

    properties.delete_if{|prop|deleting_props.include?(prop["date"])}

    self.count_properties = properties.to_json
    save

    return deleted_events
  end

  def add_image_event_evidence_for_graph(event_ids)
    properties = count_properties ? JSON.parse(count_properties) : []
    return [] if properties.empty?

    hash = {}
    ev = Event.where(id: event_ids)
    item_image_ids = ev.each do |e|
      img_id = eval(e.properties)[:item_image_id]
      ii = ItemImage.where(id: img_id).first
      next unless ii
      ii.added_at = Time.now unless ii.added_at
      hash_key = ii.added_at.to_date.to_s
      if hash.has_key?(hash_key)
        hash[hash_key] << e.id
      else
        hash[hash_key] = [e.id]
      end
    end

    last_date = Date.new(1970,1,3)
    properties.each_with_index do |prop, i|
      is_evidence_exist = hash.has_key?(prop["date"])
      if is_evidence_exist
        prop["events"].concat(hash[prop["date"]])
        hash.delete(prop["date"])
      end
    end

    hash.each do |date, e_id|
      h = {}
      h["date"] = date
      h["count"] = nil
      h["events"] = e_id
      properties.push(h)
    end

    properties.sort_by!{|pr|Date.parse(pr["date"])}

    properties.each_with_index do |prop, i|
      next if prop["count"]
      if i == 0
        prop["count"] = 0
      else
        prop["count"] = properties[i - 1]["count"]
      end
    end

    self.count_properties = properties.to_json
    pp self
    save

    # return deleted_events
  end

  def add_image_lacking_error_of_list
    errors.add(:image, "cant be blank")
  end

  def self.get_timestamp_without_millis(time)
    time = time.to_s
    time = time.slice(0...10) if time.size > 10
    return time.to_i
  end

  def thumbnail
    if item_image = self.item_images.last
      return item_image.image_url
    else
      return nil
    end
  end

  def to_light
    {
      id:      self.id,
      name:    self.name,
      is_list: self.is_list,
      count:   self.count,
      image:   self.thumbnail,
      path:    Rails.application.routes.url_helpers.item_path(self.id)
    }
  end

  def showing_events(relation_with_owner = 0)
    # TODO: 何日前まで取得するか決める
    properties_by_day = JSON.parse(self.count_properties)
    events = Event.where(id: properties_by_day.map{|prop|prop["events"]}.flatten)
    properties_by_day.each do |prop|
      event_ids = prop["events"]

      # count_propertiesにあるイベントと関連アイテムを全部一気に取得
      # いちいち取得してたら発行するSQLがすごい数になるから
      events_of_the_day = events.select{|e|event_ids.include?(e.id)}
      item_ids = []
      events_of_the_day.each do |e|
        if e.event_type == "add_image"
          item_ids << e.related_id
        else
          item_ids << eval(e.properties)[:item_id]
        end
      end
      items = Item.where(id: item_ids)

      # 日ごとに記録してるevent_idsをイベントオブジェクトに置き換え
      event_objects = []
      events_of_the_day.each do |e|
        hash = {}
        hash["event_type"] = e.event_type
        if e.event_type == "add_image"
          item = items.detect{|i|i.id == e.related_id}
          image_id = eval(e.properties)[:item_image_id]
          adding_image = ItemImage.where(id: image_id).first
          adding_image = adding_image.image_url if adding_image
        elsif e.event_type == "change_count"
          next
        else
          item = items.detect{|i|i.id == eval(e.properties)[:item_id]}
        end
        hash["item"] = item.to_light if item.present?
        if adding_image.present?
          hash["item"][:thumbnail] = adding_image 
        end
        event_objects << hash
      end
      prop["events"] = event_objects
    end
    properties_by_day
  end

  def can_show?(user)
    relation_to_owner = get_relation_to_owner(user)

    relation_to_owner >= Item.private_types[self.private_type]
  end

  def get_relation_to_owner(user)
    relation_to_owner = Relation::NOTHING unless user.present?
    relation_to_owner = Relation::HIMSELF if user.present? && user.id == self.user_id

    unless relation_to_owner
      followers = self.user.followed.map(&:id)
      followings = self.user.following.map(&:id)

      if followers.include?(user.id) && followings.include?(user.id)
        relation_to_owner = Relation::FRIEND
      elsif followers.include?(user.id) && !followings.include?(user.id)
        relation_to_owner = Relation::FOLLOWED
      else
        relation_to_owner = Relation::NOTHING
      end
    end

    return relation_to_owner
  end

  def breadcrumb(include_self = false)
    return self.user.name + "さんの持ち物" unless list_id
    if include_self
      result = self.list.breadcrumb(include_self) + " > " + self.name
    else
      result = self.list.breadcrumb(true) + " > "
    end
    return result
  end

  def get_parent_list_ids(ids = [])
    return false if ids.detect{|e|ids.count(e) > 1}

    if self.list_id
      ids << self.list_id
      self.list.get_parent_list_ids(ids)
    else
      return ids
    end
  end

  def is_recursive_list?
  end

  def can_add_timer?
    return false unless is_list
    Timer::MAX_COUNT_PER_LIST > timers.count
  end

end
