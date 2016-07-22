class WelcomeController < ApplicationController

  before_action :authenticate_user!

  def index
    @current_user = current_user
  end

  def home
    @current_user = current_user
    @timeline = following_timeline(nil, 5) if @current_user
  end

  def timeline
    @current_user = current_user
    # TODO: beforeの取得
    #       最終取得から1日経ったあとに最新のイベントを取得するとき
    #       何件取得するか分からない
    #       今のところ過去に取得したものを全消しして再度最初から
    #       取得しなおしにしてるけど、いつか最新取得出来るようにしたい
    from = params[:from].to_i rescue 0
    @timeline = following_timeline(from) if @current_user

    respond_to do |format|
      format.html {render partial: 'shared/timeline', layout: false, locals: {timeline: @timeline, has_next_event: @has_next_event, is_home: true}}
      format.json
    end
  end

  def item_graph
    @chart_detail = JSON.parse(current_user.chart.chart_detail)
  end

  def pickup
    @popular_tag = get_popular_tag
    @popular_list = get_popular_list
  end

  def popular_tag
    @popular_tag = get_popular_tag
  end

  def popular_list
    @popular_list = get_popular_list
  end

  private
  def following_timeline(from = 0, size = User::MAX_SHOWING_EVENTS)
    timeline = []
    @current_user.following.each do |user|
      timeline.concat(user.timeline(@current_user, from, size))
    end
    n = timeline.size
    0.upto(n - 2) do |i|
      (n - 1).downto(i + 1) do |j|
        if timeline[j][:event_id] > timeline[j - 1][:event_id]
          timeline[j], timeline[j - 1] = timeline[j - 1], timeline[j]
        end
      end
    end
    @has_next_event = (n.size > 0) ? true : false
    timeline
  end


  # cacheは今のところtmpディレクトリに入れる
  # （デフォルトのまま、redisなどに変更してない）
  # cachestoreについて: http://guides.rubyonrails.org/caching_with_rails.html
  # redis使うにしてもexpireを指定しないといけない
  # http://stackoverflow.com/questions/14404584/what-is-the-default-expiry-time-for-rails-cache
  # また、キャッシュするのもARオブジェクトとかじゃなくて
  # idなどの動的な変更がないものにする
  # http://stackoverflow.com/questions/11218917/confusion-caching-active-record-queries-with-rails-cache-fetch?answertab=votes#tab-top
  def get_popular_tag
    tag_hash = Rails.cache.fetch('popular_tags', expires_in: 6.hours) do
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

  def get_popular_list
    popular_list_ids = Rails.cache.fetch('popular_list', expires_in: 6.hours) do
      items = Item
        .includes(:tags, :item_images, :favorites)
        .joins(:item_images)
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

end
