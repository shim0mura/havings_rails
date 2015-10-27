class ItemsController < ApplicationController

  # before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_item, only: [:show, :timeline, :edit, :update, :destroy]

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

    line_chart

  end

  def timeline
    @from = params[:from]
    render partial: 'timeline', layout: false
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
    @item = Item.new(item_params)
    @item.user_id = current_user.id
    @item.list_id = current_user.get_home_list.id unless @item.list_id
    @item.count = 0 if @item.is_list

    if @item.save
      new_item_event = Event.create(
        event_type: (@item.is_list ? :create_list : :create_item),
        acter_id: current_user.id,
        related_id: @item.list_id,
        properties: {
          item_id: @item.id
        }
      )

      image_event = create_image!

      if @item.is_garbage
        # list側から捨てたことを知りたいのと
        # item側から手放されたことを知りたいので2つイベントを入れる
        # 設計ミス…
        dump_from_list_event = Event.create(
          event_type: :dump,
          acter_id: current_user.id,
          related_id: @item.list_id,
          properties: {
            item_id: @item.id
          }
        )
        dump_as_item_event = Event.create(
          event_type: :dump,
          acter_id: current_user.id,
          related_id: @item.id
        )
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
          @item.change_count(@item.count, new_item_event)
        end
      end
      if (image_event.present? && @item.is_list)
        @item.change_count(0, image_event, @item)
      end

      render json: { status: :ok, location: @item }
      # format.html { redirect_to @item, notice: 'Item was successfully created.' }
      # format.json { render :show, status: :created, location: @item }
    else
      render json: { location: @item }, status: :unprocessable_entity
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
    # respond_to do |format|
    if @item.update(item_params)
      delete_image!
      image_event = create_image!

      if @item.count != item_count_before_update
        Event.create(
          event_type: :change_count,
          acter_id: current_user.id,
          related_id: @item.id,
          properties: {
            before: item_count_before_update,
            after: @item.count
          }
        )
      end

      if @item.is_garbage
        # list側から捨てたことを知りたいのと
        # item側から手放されたことを知りたいので2つイベントを入れる
        # 設計ミス…
        dump_from_list_event = Event.create(
          event_type: :dump,
          acter_id: current_user.id,
          related_id: @item.list_id,
          properties: {
            item_id: @item.id
          }
        )
        dump_as_item_event = Event.create(
          event_type: :dump,
          acter_id: current_user.id,
          related_id: @item.id
        )
      end

      # グラフのための情報を更新
      # グラフは今のところリストからしか参照しないので、リストに関するイベントと
      # リストに属するアイテムの個数変化のみ記録
      # 1. アイテムorリストの手放し
      # 2. アイテムの個数変化
      # 3. リストの画像追加
      # TODO: リストを手放した時、そのリストに属していたアイテムも
      # 手放せるようにしたいので、それに対応する
      if dump_from_list_event
        count_diff = (@item.is_list ? 0 : @item.count * (-1))
        @item.change_count(count_diff, dump_from_list_event)
      elsif @item.count != item_count_before_update
        @item.change_count(@item.count - item_count_before_update)
      elsif (image_event.present? && @item.is_list)
        @item.change_count(0, image_event, @item)
      end

      unless private_type_before_update == @item.private_type
        synchronize_with_list
      end

      #format.html { redirect_to @item, notice: 'Item was successfully updated.' }
      render json: { status: :ok, location: @item }
    else
      # format.html { render :edit }
      # format.json { render json: @item.errors, status: :unprocessable_entity }
      render json: { location: @item }, status: :unprocessable_entity
    end
    # end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item.update_attribute('is_deleted', true)
    # 関連イベントも全て論理削除
    delete_events
    unless @item.is_list
      @item.change_count(@item.count * (-1))
    end

    respond_to do |format|
      format.html { redirect_to items_url, notice: 'Item was successfully destroyed.' }
      format.json { head :no_content }
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

    def delete_image!
      if params[:item][:image_deleting]
        deleting_image_ids = params[:item][:image_deleting].map(&:to_i)
        @item.item_images.each do |image|
          if deleting_image_ids.include?(image.id)
            image.update_attribute('item_id', nil)
          end
        end
      end
    end

    def create_image!
      return false unless params[:item][:item_images]

      item_image_ids = []
      params[:item][:item_images].each do |a|
        item_image = @item.item_images.create!(:image => a)
        item_image_ids.push(item_image.id)
      end

      Event.create(
        event_type: :add_image,
        acter_id: current_user.id,
        related_id: @item.id,
        properties: {
          item_image_ids: item_image_ids
        }
      )
    end

    def delete_events
      list_event = Event.where(
        acter_id: current_user.id,
        related_id: @item.list_id
      )
      list_events = []
      list_event.each do |event|
        next unless event.properties
        item_id = eval(event.properties)[:item_id]
        list_events.push(event.id) if item_id == @item.id
      end

      item_events = Event.where(
        acter_id: current_user.id,
        related_id: @item.id
      ).collect{|e|e.id}
      
      Event.where(id: item_events.concat(list_events))
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

    end

    def is_owned_item?
      unless user_signed_in? && current_user.id == @item.user_id
        redirect_to items_path
      end
    end

    def is_already_droped?
      if @item.is_garbage
        redirect_to items_path
      end
    end

    def line_chart
      gon.item = @item.showing_events
    end


end
