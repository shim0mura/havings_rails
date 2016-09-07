class ItemsController < ApplicationController

  include CarrierwaveBase64Uploader

  before_action :authenticate_user!, only: [:done_task, :create, :edit, :update, :destroy, :dump, :add_image, :update_image_metadata, :destroy_image]
  #before_action :authenticate_user!
  before_action :set_item, only: [:show, :next_items, :next_images, :item_image, :timeline, :done_task, :showing_events, :edit, :update, :destroy, :dump, :add_image, :update_image_metadata, :destroy_image]
  before_action :can_show?, only: [:show, :next_items, :next_images, :item_image, :timeline, :done_task, :showing_events, :edit, :update, :destroy, :update_image_metadata, :destroy_image]
  before_action :can_edit?, only: [:update, :destroy, :dump, :add_image, :update_image_metadata, :destroy_image]

  def dummy
    seconds = params[:seconds].to_i || 3
    sleep(seconds)
    render json: { status: :ok, time: seconds }
  end

  def tes
    pp params
    pp current_user.name
  end

  # GET /items
  # GET /items.json
  def index
    @items = Item.all
  end

  # GET /items/1
  # GET /items/1.json
  def show
    @new_item = Item.new
    @list = current_user.items.as_list if user_signed_in?
    # to_aすればARをloadしない
    # @lista = @list.to_a
    @timer = Timer.new(list_id: @item.id)

    @relation = (current_user.present? && current_user.id == @item.user_id) ? Relation::HIMSELF : Relation::NOTHING

    @done_tasks = 0
    if user_signed_in? && @item.user_id == current_user.id
      task = Timer.done_tasks(@item.user_id, @item.id)
      @done_tasks = task.map{|t|t[:events].size}.sum
    end

    get_next_items

    get_next_images

    line_chart

  end

  def next_items
    page = params[:page]
    get_next_items(page)

  end

  def next_images
    page = params[:page]
    get_next_images(page)

  end

  def item_image
    @item_image = ItemImage.where(id: params[:image_id], item_id: @item.id).first
    @user_id = (current_user.present? ? current_user.id : nil)
    render json: { errors: {image_not_found: ["."]}}, status: :unprocessable_entity unless @item_image.present?
  end

  def timeline
    @from = params[:from]
    render partial: 'timeline', layout: false
  end

  def done_task
    redirect_to @item unless @item.is_list
    @tasks = Timer.done_tasks(current_user.id, @item.id)
  end

  def showing_events
  end

  # GET /items/new
  def new
    @item = Item.new
    @item_image = @item.item_images.build
    @list = current_user.items.as_list
  end

  # GET /items/1/edit
  def edit
    @item_images = @item.item_images
    @list = current_user.items.as_list
  end

  # POST /items
  # POST /items.json
  def create
    # p JSON.parse(params["item"])
    # params[:item] = JSON.parse(params[:item])
    # puts request.headers['HTTP_ACCEPT']
    # p request.headers["CONTENT_TYPE"]
    # p request.format
    # p request.content_type
    pp params
    p item_params
    set_posted_image_data

    # data = base64_conversion(params["item"]["image_data"])
    #ItemImage.create!(:image => data)
    @item = Item.new(item_params)

    @item.user_id = current_user.id
    @item.count = 0 if @item.is_list


    unless @item.list_id
      @item.list_id = current_user.get_home_list.id
    else
      unless is_own_list?(@item.list_id)
        render json: { errors: {} }, status: :unprocessable_entity
        return
      end
    end

    synchronize_private_type_by_parent

    if @item.is_list && !is_image_appended?
      @item.add_image_lacking_error_of_list
      render json: { errors: @item.errors }, status: :unprocessable_entity
      return
    end

    @item.is_garbage = false if @item.is_garbage.nil?

    pp @posted_image_data
    pp @item

    begin
      ActiveRecord::Base.transaction do

        @item.save!
        new_item_event = Event.create!(
          event_type: (@item.is_list ? :create_list : :create_item),
          acter_id: current_user.id,
          related_id: @item.list_id,
          properties: {
            item_id: @item.id
          }
        )

        if @item.is_garbage
          # list側から捨てたことを知りたいのと
          # item側から手放されたことを知りたいので2つイベントを入れる
          # 設計ミス…
          # => dump_from_list_eventをitemとそれを内包するlistに持たせるから
          # わざわざ2つ作る必要はない？
          dump_from_list_event = Event.create!(
            event_type: :dump,
            acter_id: current_user.id,
            related_id: @item.list_id,
            properties: {
              item_id: @item.id
            }
          )
          # dump_as_item_event = Event.create(
          #   event_type: :dump,
          #   acter_id: current_user.id,
          #   related_id: @item.id
          # )
        end

        # グラフのための情報を更新
        if @item.is_garbage
          @item.change_count(0, dump_from_list_event)
        else
          if @item.is_list
            @item.change_count(0, new_item_event, @item)
          else
            @item.change_count(0, new_item_event)

            @item.tags.reload
            Chart.add_item_to_total_chart(item: @item, count: @item.count)
          end
        end

        create_image!(@posted_image_data)
        end

      render json: json_rendered_item
      # format.html { redirect_to @item, notice: 'Item was successfully created.' }
      # format.json { render :show, status: :created, location: @item }


    rescue => e
      logger.error("item_create_failed, user_id: #{current_user.id}, #{e}, #{e.backtrace}")
      if @item.errors.messages.present?
        render json: {errors: @item.errors}, status: :unprocessable_entity
      else
        render json: { }, status: 500
      end
    end
  end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    # is_private = @item.is_private
    private_type_before_update = @item.private_type
    item_count_before_update = @item.count
    list_id_before_update = @item.list_id
    tags_before_update = @item.tags.map(&:id)
    dump_before_update = @item.is_garbage

    set_posted_image_data

    # list.list_id == list.idのチェック
    # 再起で死ぬので
    # tag_listが空だとおかしくなる？
    # ev = @item.delete_image_event_evidence_for_graph(params[:item][:image_deleting])
    # p ev
    if params[:item][:list_id].nil? || params[:item][:list_id] == @item.id
      params[:item][:list_id] = @item.list_id
    elsif @item.list_id.nil?
      params[:item][:list_id] = nil
    end

    # 再起対策
    parent_list_ids = @item.get_parent_list_ids
    if @item.is_list && !parent_list_ids
      params[:item][:list_id] = current_user.get_home_list.id
    elsif @item.is_list && params[:item][:list_id]
      parent = Item.where(id: params[:item][:list_id]).first
      parent = current_user.get_home_list unless parent
      pli = parent.get_parent_list_ids
    end

    synchronize_private_type_by_parent

    pp parent_list_ids
    pp Item.where(id: params[:item][:list_id]).first.get_parent_list_ids

    if @item.is_garbage
      params[:item].delete(:count)
    end

    # respond_to do |format|
    begin
      ActiveRecord::Base.transaction do
      
        @item.update!(item_params)

        # 属するリストを変更、且つその対象リストが自分の子リストだった場合
        # 再帰させないように処理
        if @item.is_list && !@item.get_parent_list_ids
          target_list_position = pli.index(@item.id)
          unless target_list_position
            @item.list_id = pli.first
            @item.save
          else

            changed_parent_id = pli[target_list_position + 1]
            changed_parent_id = current_user.get_home_list.id unless changed_parent_id
            parent.list_id = changed_parent_id
            parent.save
          end
        end


        if @item.count != item_count_before_update
          count_changed = Event.create!(
            event_type: :change_count,
            acter_id: current_user.id,
            related_id: @item.id,
            properties: {
              before: item_count_before_update,
              after: @item.count,
              is_garbage: @item.is_garbage
            }
          )
        end

        if @item.count != item_count_before_update
          # アイテムの個数変化
          pp "#item_count change #{@item.count} #{item_count_before_update}"
          @item.change_count(@item.count - item_count_before_update, count_changed)
        # elsif @item.is_list && (@item.list_id != list_id_before_update)
        elsif (@item.list_id != list_id_before_update)
          # リストを別のリストに変更した時
          current_parent_list_ids = @item.get_parent_list_ids

          target_history = JSON.parse(@item.count_properties)

          p "#"*20
          p (parent_list_ids - current_parent_list_ids)
          (parent_list_ids - current_parent_list_ids).each do |i|
            p = Item.where(id: i).first
            p.delete_events_history(target_history) if p.present?
            p.reload
          end
          p "$"*20
          p (current_parent_list_ids - parent_list_ids)
          (current_parent_list_ids - parent_list_ids).each do |i|
            p = Item.where(id: i).first
            p.add_events_history(target_history) if p.present?
            p.reload
          end
          pp "&"*20

          @item.reload
          @item.change_count
          prev_parent = Item.where(id: list_id_before_update).first
          prev_parent.change_count if prev_parent.present?
        end


        # アイテム個数の全体における割合計算
        if !@item.is_garbage && !@item.is_list

          tags = @item.tags.reload
          tags_before_update = ActsAsTaggableOn::Tag.where(id: tags_before_update)

          if !(tags - tags_before_update).empty? && @item.count != item_count_before_update
            Chart.delete_item_to_total_chart(item: @item, count: item_count_before_update, tag: tags_before_update)
            Chart.add_item_to_total_chart(item: @item, count: @item.count, tag: tags)

          elsif !(tags - tags_before_update).empty?
            # 一旦、前のタグに紐付いた値を消してから新しい物を追加
            # Pコートタグをダッフルコートタグに変えたとしても
            # 一旦Pコートとそれに関係する親の値も消してから
            # 再度ダッフルコートを追加するので、タグの範囲が被ってても問題ない
            Chart.delete_item_to_total_chart(item: @item, count: @item.count, tag: tags_before_update)
            Chart.add_item_to_total_chart(item: @item, count: @item.count, tag: tags)
          elsif @item.count != item_count_before_update
            count_diff = @item.count - item_count_before_update

            if count_diff > 0
              Chart.add_item_to_total_chart(item: @item, count: count_diff)
            else
              Chart.delete_item_to_total_chart(item: @item, count: count_diff * (-1))
            end

          end
        end

        unless private_type_before_update == @item.private_type
          if @item.private_type > 0
            synchronize_with_list
          end
        end

        #format.html { redirect_to @item, notice: 'Item was successfully updated.' }
        # render json: json_rendered_item
        # else
          # format.html { render :edit }
          # format.json { render json: @item.errors, status: :unprocessable_entity }
        # render json: {errors: @item.errors}, status: :unprocessable_entity
      end
      render json: json_rendered_item
    rescue => e
      logger.error("item_update_failed, item_id: #{@item.id}, #{e}, #{e.backtrace}")
      if @item.errors.messages.present?
        render json: {errors: @item.errors}, status: :unprocessable_entity
      else
        render json: { }, status: 500
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    fellow_ids = params[:fellow_ids].present? ? params[:fellow_ids].map(&:to_i) : []

    begin
      ActiveRecord::Base.transaction do
    
        @item.update_attributes!(is_deleted: true)

        # dumpしてるものは既にchartからカウント対象として外されてるので
        # 二重に計算しないようにする
        unless @item.is_garbage
          Chart.delete_item_to_total_chart(item: @item, count: @item.count)
        end

        @item.timers.each do |t|
          t.is_deleted = true
          t.is_active = false
          t.save!
        end

        if @item.is_list
          children = @item.child_items.countable
          fellow_ids = params[:fellow_ids].present? ? params[:fellow_ids].map(&:to_i) : []
          delete_fellow_children, unchanged_children = children.partition do |c|
            fellow_ids.include?(c.id)
          end

          parent_item = @item.list
          unchanged_children.each do |c|
            c.list_id = parent_item.id
            c.save!
          end

          delete_fellow_children.each do |c|
            unless c.is_garbage
              Chart.delete_item_to_total_chart(item: c, count: c.count)
            end

            c.timers.each do |t|
              t.is_deleted = true
              t.is_active = false
              t.save!
            end

            c.delete_recursive
            delete_events(c.get_event_recursive)
          end
        end

        @item.get_parent_list_ids.each do |i|
          p = Item.where(id: i).first
          target_history = JSON.parse(@item.count_properties)
          
          p.delete_events_history(target_history) if p.present?
          p.reload
        end
        @item.reload
        @item.change_count(0)

        delete_events(@item.get_item_related_event)

      end
      respond_to do |format|
        format.html { redirect_to items_url, notice: 'Item was successfully destroyed.' }
        format.json {render json: json_rendered_item}
      end
    rescue => e
      # render json: json_rendered_item, status: 500
      logger.error("delete_failed, item_id: #{@item.id} ,#{e}, #{e.backtrace}")
      
      if @item.errors.messages.present?
        render json: {errors: @item.errors}, status: :unprocessable_entity
      else
        render json: { }, status: 500
      end
    end
  end

  def dump

    begin
      ActiveRecord::Base.transaction do
    
        @item.update!(item_params)
        # アイテムの手放し
        dump_from_list_event = Event.create!(
          event_type: :dump,
          acter_id: current_user.id,
          related_id: @item.list_id,
          properties: {
            item_id: @item.id
          }
        )

        Chart.delete_item_to_total_chart(item: @item, count: @item.count)

        @item.timers.each do |t|
          t.is_active = false
          t.save!
        end

        if @item.is_list && params[:item][:fellow_ids].present?
          children = @item.child_items.countable
          fellow_ids = params[:item][:fellow_ids].map(&:to_i)
          dump_fellow_children, unchanged_children = children.partition do |c|
            fellow_ids.include?(c.id)
          end

          parent_item = @item.list
          unchanged_children.each do |c|
            c.list_id = parent_item.id
            c.save!
          end

          dump_fellow_children.each do |c|
            unless c.is_garbage
              Chart.delete_item_to_total_chart(item: c, count: c.count)
            end
            c.timers.each do |t|
              t.is_active = false
              t.save!
            end
            c.dump_recursive
          end
        end

        @item.change_count(0, dump_from_list_event)

      end
      render json: json_rendered_item
    rescue => e
      logger.error("dump_failed, item_id: #{@item.id} ,#{e}, #{e.backtrace}")
      
      if @item.errors.messages.present?
        render json: {errors: @item.errors}, status: :unprocessable_entity
      else
        render json: { }, status: 500
      end
    end

  end

  def add_image
    set_posted_image_data(has_image_data: true)

    begin
      item_image_ids = []
      ActiveRecord::Base.transaction do
        item_image_ids = create_image!(@posted_image_data)
      end

      @next_images = ItemImage.where(id: item_image_ids)
      @has_next_image = false
      @next_page_for_item = 0
    rescue => e
      logger.error("add_image_failed, item_id: #{@item.id}, #{e}, #{e.backtrace}")
      render json: { }, status: 500
    end

  end

  def update_image_metadata
    set_posted_image_data(has_image_data: false)

    image_id = params[:image_id].to_i

    begin
      ActiveRecord::Base.transaction do

        meta_data = @posted_image_data.first
        image = ItemImage.where(id: image_id).first

        raise if !meta_data.present? && !image.present?

        image.update_attributes!(
          memo: meta_data[:memo],
          added_at: Time.at(Item.get_timestamp_without_millis(meta_data[:timestamp]))
        )

        event_ids = @item.detect_deleting_image_event_from_image_id([image_id])
        @item.delete_image_event_evidence_for_graph(event_ids)
        @item.add_image_event_evidence_for_graph(event_ids)

      end
      render json: { status: :ok }
    rescue => e
      logger.error("update_image_metadata_failed, item_id: #{@item.id}, image_id: #{image_id}, #{e}, #{e.backtrace}")
      
      render json: { }, status: 500
    end
  end

  def destroy_image
    image_id = params[:image_id].to_i
    pp image_id

    begin
      ActiveRecord::Base.transaction do

        deleting_event_ids = @item.detect_deleting_image_event_from_image_id([image_id])

        @item.delete_image_event_evidence_for_graph(deleting_event_ids)
        image = ItemImage.find(image_id)
        image.update!(item_id: nil)

        Event.create(
          event_type: :delete_image,
          acter_id: current_user.id,
          related_id: @item.id,
          is_deleted: true,
          properties: {
            item_image_id: image_id
          }
        )


      end
      render json: { status: :ok }
    rescue => e
      logger.error("destroy_image_failed, item_id: #{@item.id}, image_id: #{image_id}, #{e}, #{e.backtrace}")
      
      render json: { }, status: 500
    end

  end


  private

    def set_item
      @item = Item.includes(child_items:[:tags, :item_images, :favorites]).find(params[:id])
      #@child_items = @item.child_items
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def item_params
      params.require(:item).permit(:name, :description, :is_list, :is_garbage, :private_type, :count, :garbage_reason, :tag_list, :list_id)
    end

    def json_rendered_item
      rendered_item = @item.to_light
      rendered_item[:thumbnail] = rendered_item[:image]
      rendered_item[:tags] = @item.tag_list
      rendered_item[:favorite_count] = @item.favorites.size
      rendered_item[:list_id] = @item.list_id
      return rendered_item
    end

    def set_posted_image_data(has_image_data: true)
      if request.format.json?
        @posted_image_data = []
        if params[:item][:image_data_for_post].present?
          params[:item][:image_data_for_post].each do |i|
            hash = {}
            hash[:data] = base64_conversion(i["image_data"]) if has_image_data
            hash[:memo] = i["memo"]
            if i["added_date"].is_a? String
              pp "image date parse by 'added_date'"
              time = Time.parse(i["added_date"]).to_f rescue Time.now.to_f
            else
              pp "image date parse by 'date'"
              time = i["date"]
            end
            hash[:timestamp] = Item.get_timestamp_without_millis(time)

            @posted_image_data << hash
          end
        end
      else
        @posted_image_data = params[:item][:item_images] || []
      end
    end

    def create_image!(uploaded_images = [])
      return false unless uploaded_images.present?

      item_image_ids = []
      uploaded_images.each do |image|
        item_image = @item.item_images.create!(
          image: image[:data],
          memo: image[:memo],
          added_at: Time.at(image[:timestamp])
        )
        item_image_ids.push(item_image.id)
      end

      event_ids = item_image_ids.map do |ii|
        Event.create!(
          event_type: :add_image,
          acter_id: current_user.id,
          related_id: @item.id,
          properties: {
            item_image_id: ii
          }
        )
      end

      @item.add_image_event_evidence_for_graph(event_ids)
      return item_image_ids
    end

    def delete_events(event_ids)
      Event.where(id: event_ids)
        .update_all(is_deleted: true)
    end

    def synchronize_with_list
      if @item.is_list
        @item.child_items.each do |i|
          i.update_attribute(:private_type, @item.private_type)
        end
      end
    end

    # 親リストが非公開の場合
    # その子孫アイテム/リストも非公開になる
    # 親リストが非公開で子孫アイテムが公開として設定されていた場合に修正
    def synchronize_private_type_by_parent
      list = Item.find(@item.list_id)
      if list.private_type > @item.private_type
        @item.private_type = list.private_type
      end
    end

    def can_show?
      unless @item.can_show?(current_user)
        redirect_to user_page_path(@item.user_id)
      end
    end

    def can_edit?
      unless @item.user_id == current_user.id
        render json: { }, status: 500
        return
      end
    end

    def is_already_droped?
      if @item.is_garbage
        redirect_to items_path
      end
    end

    def is_own_list?(list_id)
      list = Item.where(id: list_id).first
      return false unless list
      return current_user.id == list.user_id
    end

    def is_image_appended?
      return @posted_image_data.present?
    end

    def line_chart
      gon.item = @item.showing_events
    end

    def get_next_items(page = 0)
      @next_items = @item.next_items(current_user, page)
      @has_next_item = !@next_items.last_page?
      @next_page_for_item = @has_next_item ? @next_items.current_page + 1 : nil
    end

    def get_next_images(page = 0)
      @next_images = @item.next_images(page)
      @has_next_image = !@next_images.last_page?
      @next_page_for_image = @has_next_image ? @next_images.current_page + 1 : nil
    end

end
