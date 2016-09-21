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

  paginates_per 10

  include EnumType

  acts_as_taggable

  enum private_type: %i(global follower friends secret)

  belongs_to :user
  has_many :item_images

  has_many :favorites
  has_many :image_favorites

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

  scope :dump, -> { where(is_garbage: true) }

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

  def next_items(user = nil, page = 0, limit = SHOWING_ITEM)
    relation_to_owner = self.user.get_relation_to(user)

    Item
       .includes(:item_images, :tags, :favorites)
       .countable
       .where(
         list_id: self.id
       )
       .where("private_type <= ?", relation_to_owner)
       .order("id DESC")
       .page(page)

    # if from != 0
    #   from_option = Item.arel_table[:id].lt(from)
    #   i = Item.where(from_option)
    # else 
    #   i = Item
    # end

    # relation_to_owner = self.user.get_relation_to(user)

    # i
    #   .includes(:item_images, :tags, :favorites)
    #   .countable
    #   .where(
    #     list_id: self.id
    #   )
    #   .where("private_type <= ?", relation_to_owner)
    #   .order("id DESC")
    #   .limit(limit)
  end

  def next_images(page = 0)
    ItemImage
        .where(item_id: self.id)
        .order("id DESC")
        .includes(:image_favorites)
        .page(page)

    # image = ItemImage.where(id: from).first if from != 0
    # if image
    #   from_time = image.created_at
    # else 
    #   from_time = Time.now
    # end

    # ItemImage.where(item_id: self.id)
    #   .where("created_at < ?", from_time)
    #   .order("created_at DESC")
    #   .limit(limit)
  end

  # def self.dump_items(user, viewer = nil, from = 0, limit = SHOWING_ITEM)
  #   if from != 0
  #     from_option = Item.arel_table[:id].lt(from)
  #     i = Item.where(from_option)
  #   else 
  #     i = Item
  #   end

  #   relation_to_owner = user.get_relation_to(viewer)

  #   i
  #     .includes(:item_images, :tags, :favorites)
  #     .dump
  #     .where(user_id: user.id)
  #     .where("private_type <= ?", relation_to_owner)
  #     .order("id DESC")
  #     .limit(limit + 1)
  # end

  def get_nested_child_item(from = 0)
    nested_child_item_ids = []
    items = Item.countable.includes(:child_items).where(user_id: self.user_id)

    queue = self.child_items.to_a

    while !queue.empty?
      item = queue.shift
      pp item
      next unless item.present?
      nested_child_item_ids << item.id
      queue << item.child_items.to_a
      queue.flatten!
    end

    return nested_child_item_ids
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

    self.timers.each do |t|
      t.is_active = false
      t.save!
    end

    dump_event = Event.create!(
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

    self.timers.each do |t|
      t.is_deleted = true
      t.is_active = false
      t.save!
    end

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

    item_event = Event.where(
      acter_id: self.user_id,
      related_id: self.id,
      event_type: Event.item_related_event_types
    )
    item_events = []
    list_event.each do |event|
      next unless event.properties
      item_id = eval(event.properties)[:item_id] rescue nil
      item_events.push(event.id) if item_id == self.id
    end

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

  def delete_events_history(target_events)
    properties = JSON.parse(self.count_properties)
    properties.sort_by!{|pr|Date.parse(pr["date"])}
    target_events.sort_by!{|pr|Date.parse(pr["date"])}
    deleting_events = Marshal.load(Marshal.dump(target_events))

    target = deleting_events.shift
    next_target = deleting_events.shift
    unless next_target
      next_target = target
      next_target["date"] = Date.today.to_s
    end
    first_added_date = Date.parse(target["date"])
    prev_count = properties.first["count"]
    deleting_props = []

    # countも削除対象のアイテム数に応じて変える必要がある
    # 対象アイテムの親リストはイベント履歴が対象アイテムより多いはずなので
    # 1. 対象アイテムの記録日と親リストの記録日が同じ
    # 2. 対象アイテムの記録日と親リストの記録日が違う
    #    (親リストに属する別のアイテムの個数変化など）
    # の2パターンが考えられる
    # 削除したいイベント履歴日(A)とその次の削除したいイベント履歴日(B)の間に
    # 2.のようなパターンがありえるので、それを2番目のelsif節で処理してる
    # 4,5番目のelse節は今のところ考えられないけど、
    # 考慮漏れなどのことも考えて入れておく
    properties.each_with_index do |h, i|
      date = Date.parse(h["date"])
      target_date = Date.parse(target["date"])
      next_target_date = Date.parse(next_target["date"])
      # next unless first_added_date > date
      if first_added_date > date
        p "next #{first_added_date} #{date}"
        next
      end

      if date == target_date
        h["count"] = h["count"] - target["count"]
        dup = h["events"] & target["events"]
        if dup.present?
          h["events"].delete_if{|e|dup.include?(e)}
          deleting_props << h if h["events"].empty? && prev_count == h["count"]
        end
        p "same date target #{date}, #{next_target} "

      elsif date > target_date && date < next_target_date
        h["count"] = h["count"] - target["count"]
        p "diff target #{date}, #{next_target} "

      elsif date == next_target_date
        h["count"] = h["count"] - next_target["count"]

        dup = h["events"] & next_target["events"]
        if dup.present?
          h["events"].delete_if{|e|dup.include?(e)}
          deleting_props << h if h["events"].empty? && prev_count == h["count"]
        end

        target = next_target
        next_target = deleting_events.shift
        unless next_target
          next_target = target
          next_target["date"] = Date.today.to_s
        end

        p "same date next_target #{date}, #{next_target}"

      elsif date < target_date
        h["count"] = h["count"] - target["count"]
      else
        h["count"] = h["count"] - target["count"]
        logger.warn("something with wrong!")
      end

      prev_count = h["count"]

    end

    properties.delete_if{|prop|deleting_props.include?(prop)}

    self.count_properties = properties.to_json
    save!
  end

  def add_events_history(target_events)
    properties = JSON.parse(self.count_properties)
    properties.sort_by!{|pr|Date.parse(pr["date"])}
    target_events.sort_by!{|pr|Date.parse(pr["date"])}
    adding_events = Marshal.load(Marshal.dump(target_events))

    result = []
    target = properties.shift
    addings = adding_events.shift
    prev_target = nil
    prev_addings = nil

    while target.present? || addings.present?

      unless target.present?
        target = {}
        target["date"] = Date.today.to_s
        target["events"] = []
        target["count"] = 0
      end

      unless addings.present?
        addings = {}
        addings["date"] = Date.today.to_s
        addings["events"] = []
        addings["count"] = 0
      end

      last_count = (result.last.present? ? result.last["count"] : 0)

      case Date.parse(target["date"]) <=> Date.parse(addings["date"])
      when -1

        if prev_target.nil?
          result_count = last_count + target["count"]
        elsif prev_addings.present?
          result_count = target["count"] + prev_addings["count"]
        end
        result << {
          "date"   => target["date"],
          "count"  => result_count,
          "events" => target["events"]
        }
        prev_target = target
        target = properties.shift

      when 0
        result_events = (target["events"] + addings["events"]).flatten.uniq

        prev_target_diff = prev_target.present? ? target["count"] - prev_target["count"] : target["count"]

        prev_addings_diff = prev_addings.present? ? addings["count"] - prev_addings["count"] : addings["count"]

        result_count = (result.last.present? ? result.last["count"] : 0) + prev_target_diff + prev_addings_diff

        result << {
          "date"   => target["date"],
          "count"  => result_count,
          "events" => result_events
        }

        prev_target = target
        target = properties.shift
        prev_addings = addings
        addings = adding_events.shift

      when 1

        if prev_addings.nil?
          result_count = last_count + addings["count"]
        elsif prev_target.present?
          result_count = addings["count"] + prev_target["count"]
        end
        result << {
          "date"   => addings["date"],
          "count"  => result_count,
          "events" => addings["events"]
        }
        prev_addings = addings

        addings = adding_events.shift

      end
    end

    self.count_properties = result.to_json
    save
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

    if self.is_list
      tree = self.user.item_tree(start_at: self.id, relation_to_owner: Relation::HIMSELF).first
      hash["count"] = tree.present? ? tree[:count] : 0
    else
      hash["count"] = self.count
    end

    hash["events"] << event.id if event.present?
    properties << hash

    self.count_properties = properties.to_json
    self.count = hash["count"].to_i
    self.save!


    if parent_list.present?
      parent_list.change_count(count_diff, event)
    end

  end

  def detect_deleting_image_event_from_image_id(item_image_ids)
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

    return hash.keys

  end


  def delete_image_event_evidence_for_graph(event_ids)
  # def delete_image_event_evidence_for_graph(item_image_ids)
    # properties = count_properties ? JSON.parse(count_properties) : []
    # return [] if properties.empty?

    # events = Event.where(
    #   event_type: Event.event_types["add_image"],
    #   acter_id: self.user_id,
    #   related_id: self.id
    # )

    # hash = {}
    # 
    # events.each do |e|
    #   item_image_id = eval(e.properties)[:item_image_id]
    #   if item_image_ids.include?(item_image_id)
    #     hash[e.id] = item_image_id
    #   end
    # end
    # pp hash

    # deleted_events = []

    # 元々add_imageしかイベントがなかったのに
    # そのadd_imageが消された場合、その日は何もイベントが起きなかったことになる
    # なので、その日の値をpropから削除する
    properties = count_properties ? JSON.parse(count_properties) : []
    deleting_props = []

    properties.each do |prop|

      dup = prop["events"] & event_ids
      if dup.present?
        prop["events"] = prop["events"] - event_ids
        deleting_props << prop["date"] if prop["events"].empty?
      end

      # prop["events"].delete_if do |e|
      #   result = hash.has_key?(e)
      #   deleted_events.push(e) if result
      #   if result && prop["events"].select{|a|a != e}.empty?
      #     deleting_props << prop["date"] 
      #   end
      #   result
      # end
      # pp prop
    end
    pp deleting_props

    properties.delete_if{|prop|deleting_props.include?(prop["date"])}

    self.count_properties = properties.to_json
    save!

    list.delete_image_event_evidence_for_graph(event_ids) if self.list

    # return deleted_events
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
    save!

    list.add_image_event_evidence_for_graph(event_ids) if self.list

    # return deleted_events
  end

  def add_image_lacking_error_of_list
    errors.add(:image, "cant be blank")
  end

  def self.get_timestamp_without_millis(time = Time.now)
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
      thumbnail: self.thumbnail,
      list_id: self.list_id,
      is_garbage: self.is_garbage,
      private_type: Item.private_types[self.private_type],
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
      item_ids.compact!
      items = Item
        .includes(:item_images, :child_items)
        .where(id: item_ids)
        .where("private_type <= ?", relation_with_owner)

      # 日ごとに記録してるevent_idsをイベントオブジェクトに置き換え
      event_objects = []
      events_of_the_day.each do |e|
        hash = {}
        hash["event_type"] = e.event_type
        if e.event_type == "add_image"
          item = items.detect{|i|i.id == e.related_id}
          next unless item.present?
          image_id = eval(e.properties)[:item_image_id]

          adding_image = item.item_images.detect{|i|i.id == image_id}

          # adding_image = ItemImage.where(id: image_id, item_id: self.id).first
        elsif e.event_type == "change_count"
          next
        else
          item = items.detect{|i|i.id == eval(e.properties)[:item_id]}
          next unless item.present?
        end
        hash["item"] = item.to_light if item.present?
        if adding_image.present?
          hash["item"][:thumbnail] = adding_image.image_url
          hash["item"][:item_image_id] = adding_image.id
        end
        event_objects << hash
      end
      prop["events"] = event_objects
    end
    properties_by_day
  end

  def can_show?(user)
    relation_to_owner = self.user.get_relation_to(user)

    relation_to_owner >= Item.private_types[self.private_type]
  end

  # def get_relation_to_owner(user)
  #   relation_to_owner = Relation::NOTHING unless user.present?
  #   relation_to_owner = Relation::HIMSELF if user.present? && user.id == self.user_id

  #   unless relation_to_owner
  #     followers = self.user.followed.map(&:id)
  #     followings = self.user.following.map(&:id)

  #     if followers.include?(user.id) && followings.include?(user.id)
  #       relation_to_owner = Relation::FRIEND
  #     elsif followers.include?(user.id) && !followings.include?(user.id)
  #       relation_to_owner = Relation::FOLLOWED
  #     else
  #       relation_to_owner = Relation::NOTHING
  #     end
  #   end

  #   return relation_to_owner
  # end

  def breadcrumb(include_self = false)
    return self.user.name + "さんの持ち物" unless list_id
    unless self.list.present?
      return self.user.name + "さんの持ち物"

    end

    if include_self
      result = self.list.breadcrumb(include_self) + " > " + self.name
    else
      result = self.list.breadcrumb(true) + " > "
    end
    return result
  end

  def get_parent_list_ids(ids = [])
    # 同じ親要素が無いか調べる
    # 属するリスト変更時に子リストを指定した場合に再帰がおきるので
    # それをcountでチェックする
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

  # cacheは今のところtmpディレクトリに入れる
  # （デフォルトのまま、redisなどに変更してない）
  # cachestoreについて: http://guides.rubyonrails.org/caching_with_rails.html
  # redis使うにしてもexpireを指定しないといけない
  # http://stackoverflow.com/questions/14404584/what-is-the-default-expiry-time-for-rails-cache
  # また、キャッシュするのもARオブジェクトとかじゃなくて
  # idなどの動的な変更がないものにする
  # http://stackoverflow.com/questions/11218917/confusion-caching-active-record-queries-with-rails-cache-fetch?answertab=votes#tab-top
  def self.get_popular_list
    popular_list_ids = Rails.cache.fetch('popular_list', expires_in: 1.hours) do
      items = Item
        .includes(:tags, :item_images, :favorites)
        .joins(:item_images)
        .where("private_type <= ?", 0)
        .order(created_at: :desc)
        .limit(100)

        # TODO: 最近追加された奴に限定したい
        #.where("items.created_at > ?", Time.now - 1.days)

      item_ids = items
        .sort_by{|i|i.favorites.size}
        .reverse
        .slice(0, 15)
        .map(&:id)
    end

    Item
      .includes(:tags, :item_images, :favorites)
      .where(id: popular_list_ids)
  end

  def self.get_popular_tag
    tag_hash = Rails.cache.fetch('popular_tags', expires_in: 3.hours) do
      popular_tags = ActsAsTaggableOn::Tag.most_used(10)

      tag_items = popular_tags.map do |tag|
        hash = {}
        hash[:tag_name] = tag.name
        hash[:tag_id]   = tag.id
        hash[:tag_count] = Item.tagged_with(tag.name).count

        items = Item
          .includes(:item_images, :favorites)
          .joins(:item_images)
          .tagged_with(tag.name)
          .order(created_at: :desc)
          .limit(100)

        items = items.sort_by{|i|i.favorites.size}.reverse
        hash[:item_ids] = items.slice(0,5).map(&:id)

        hash
      end

      tag_items
    end

    tag_hash.each do |hash|
      hash[:item] = Item
        .includes(:tags, :item_images, :favorites)
        .where(id: hash[:item_ids])
    end

    tag_hash
  end

end
