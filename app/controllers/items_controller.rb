class ItemsController < ApplicationController

  include CarrierwaveBase64Uploader

  before_action :authenticate_user!, only: [:done_task, :create, :edit, :update, :destroy, :dump]
  before_action :set_item, only: [:show, :next_items, :next_images, :timeline, :done_task, :showing_events, :edit, :update, :destroy, :dump]
  before_action :can_show?, only: [:show, :next_items, :next_images, :timeline, :done_task, :showing_events, :edit, :update, :destroy]


  def dummy
    seconds = params[:seconds].to_i || 3
    sleep(seconds)
    render json: { status: :ok, time: seconds }
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

    get_next_items

    get_next_images

    line_chart
  end

  def next_items
    from = params[:from]
    get_next_items(from)

    sleep(3)
  end

  def next_images
    from = params[:from]
    get_next_images(from)

    sleep(5)
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
    p params["item"]
    p params["item"]["image_data"]
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

    if @item.is_list && !is_image_appended?
      @item.add_image_lacking_error_of_list
      render json: { errors: @item.errors }, status: :unprocessable_entity
      return
    end

    @item.is_garbage = false if @item.is_garbage.nil?

    if @item.save
      new_item_event = Event.create(
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
        dump_from_list_event = Event.create(
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
      # グラフは今のところリストからしか参照しないので、リストに関するイベントと
      # リストに属するアイテムの個数変化のみ記録
      # 1. 手放した状態での追加
      # 2. リスト、アイテムの追加
      # 3. リストの画像追加
      if @item.is_garbage
        @item.change_count(0, dump_from_list_event)
      else
        if @item.is_list
          @item.change_count(0, new_item_event, @item)
        else
          @item.change_count(0, new_item_event)
        end
      end

      image_event = create_image!(@posted_image_data)
      # if (image_event.present? && @item.is_list)
      #   @item.change_count(0, image_event, @item)
      # end

      render json: json_rendered_item
      # format.html { redirect_to @item, notice: 'Item was successfully created.' }
      # format.json { render :show, status: :created, location: @item }
    else
      render json: {errors: @item.errors}, status: :unprocessable_entity
      # format.html { render :new }
      # format.json { render json: @item.errors, status: :unprocessable_entity }
    end
  end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    # is_private = @item.is_private
    private_type_before_update = @item.private_type
    item_count_before_update = @item.count
    list_id_before_update = @item.list_id

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

    # respond_to do |format|
    if @item.update(item_params)

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
        count_changed = Event.create(
          event_type: :change_count,
          acter_id: current_user.id,
          related_id: @item.id,
          properties: {
            before: item_count_before_update,
            after: @item.count
          }
        )
      end

      if @item.count != item_count_before_update
        # アイテムの個数変化
        @item.change_count(@item.count - item_count_before_update, count_changed)
      elsif @item.is_list && (@item.list_id != list_id_before_update)
        # リストを別のリストに変更した時
        @item.change_count
        prev_parent = Item.where(id: list_id_before_update).first
        prev_parent.change_count if prev_parent.present?
      end

      delete_image!
      added_image_event = create_image!(@posted_image_data)

      if params["item"]["image_metadata_for_update"].present?
        update_item_image_metadata(params["item"]["image_metadata_for_update"])
      end

      unless private_type_before_update == @item.private_type
        synchronize_with_list
      end

      #format.html { redirect_to @item, notice: 'Item was successfully updated.' }
      render json: json_rendered_item
    else
      # format.html { render :edit }
      # format.json { render json: @item.errors, status: :unprocessable_entity }
      render json: {errors: @item.errors}, status: :unprocessable_entity
    end
    # end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    fellow_ids = params[:fellow_ids].present? ? params[:fellow_ids].map(&:to_i) : []
    if @item.update_attribute('is_deleted', true)

      children = @item.child_items.countable
      fellow_ids = params[:fellow_ids].present? ? params[:fellow_ids].map(&:to_i) : []
      
      delete_fellow_children, unchanged_children = children.partition do |c|
        fellow_ids.include?(c.id)
      end

      parent_item = @item.list
      unchanged_children.each do |c|
        c.list_id = parent_item.id
        c.save
      end

      delete_fellow_children.each do |c|
        c.delete_recursive
        delete_events(c.get_event_recursive)
      end

      @item.change_count(0)

      delete_events(@item.get_item_related_event)

      respond_to do |format|
        format.html { redirect_to items_url, notice: 'Item was successfully destroyed.' }
        format.json json_rendered_item
      end
    else
      render json: json_rendered_item, status: :unprocessable_entity
    end
  end

  def dump
    if @item.update(item_params)
      # アイテムの手放し
      dump_from_list_event = Event.create(
        event_type: :dump,
        acter_id: current_user.id,
        related_id: @item.list_id,
        properties: {
          item_id: @item.id
        }
      )

      children = @item.child_items.countable
      fellow_ids = params[:item][:fellow_ids].map(&:to_i)
      dump_fellow_children, unchanged_children = children.partition do |c|
        fellow_ids.include?(c.id)
      end

      parent_item = @item.list
      unchanged_children.each do |c|
        c.list_id = parent_item.id
        c.save
      end

      dump_fellow_children.each do |c|
        c.dump_recursive
      end

      @item.change_count(0, dump_from_list_event)

      render json: json_rendered_item
    else
      # format.html { render :edit }
      # format.json { render json: @item.errors, status: :unprocessable_entity }
      render json: json_rendered_item, status: :unprocessable_entity
    end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params[:id])
      @child_items = @item.child_items
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

    def set_posted_image_data
      if request.format.json?
        @posted_image_data = []
        if params[:item][:image_data_for_post].present?
          params[:item][:image_data_for_post].each do |i|
            hash = {}
            hash[:data] = base64_conversion(i["image_data"])
            hash[:memo] = i["memo"]
            hash[:timestamp] = Item.get_timestamp_without_millis(i["date"])

            @posted_image_data << hash
          end
        end
      else
        @posted_image_data = params[:item][:item_images] || []
      end
    end

    def delete_image!
      if params[:item][:image_deleting]
        deleting_image_ids = params[:item][:image_deleting].map(&:to_i)
        @item.delete_image_event_evidence_for_graph(deleting_image_ids)
        @item.item_images.each do |image|
          if deleting_image_ids.include?(image.id)
            image.update_attribute('item_id', nil)
          end
        end
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
        Event.create(
          event_type: :add_image,
          acter_id: current_user.id,
          related_id: @item.id,
          properties: {
            item_image_id: ii
          }
        )
      end

      @item.add_image_event_evidence_for_graph(event_ids)
    end

    def update_item_image_metadata(meta_data)
      meta_data.each do |image_id, values|
        image = ItemImage.where(id: image_id.to_i).first
        next unless image
        image.update_attributes!(
          memo: values["memo"],
          added_at: Time.at(Item.get_timestamp_without_millis(values["timestamp"]))
        )
      end

      image_ids = params["item"]["image_metadata_for_update"].keys.map{|k|k.to_i}
      event_ids = @item.delete_image_event_evidence_for_graph(image_ids)
      p event_ids
      p @item.count_properties
      @item.add_image_event_evidence_for_graph(event_ids)
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

    def can_show?
      unless @item.can_show?(current_user)
        redirect_to user_page_path(@item.user_id)
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

    def get_next_items(from = 0)
      @next_items = @item.next_items(current_user, from)
      @has_next_item = @next_items.size >= Item::SHOWING_ITEM && @item.has_next_item_from?(current_user, @next_items.last.id)
    end

    def get_next_images(from = 0)
      @next_images = @item.next_images(from)
      @has_next_image = @next_images.size >= Item::SHOWING_ITEM && @item.has_next_images_from?(@next_images.last.id)
    end

end
