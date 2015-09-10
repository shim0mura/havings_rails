class ItemsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  # GET /items
  # GET /items.json
  def index
    @items = Item.all
  end

  # GET /items/1
  # GET /items/1.json
  def show
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

    respond_to do |format|
      if @item.save
        create_image!

        format.html { redirect_to @item, notice: 'Item was successfully created.' }
        format.json { render :show, status: :created, location: @item }
      else
        format.html { render :new }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    is_private = @item.is_private
    respond_to do |format|
      if @item.update(item_params)
        create_image!

        unless is_private == @item.is_private
          synchronize_with_list
        end

        format.html { redirect_to @item, notice: 'Item was successfully updated.' }
        format.json { render :show, status: :ok, location: @item }
      else
        format.html { render :edit }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item.destroy
    respond_to do |format|
      format.html { redirect_to items_url, notice: 'Item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def garbage
    if params[:id]
      set_item
      is_owned_item?
      @item.is_garbage = true
    else
      @item = Item.new(is_garbage: true)
    end
    render 
  end

  def drop_garbage
    if params[:id]
      set_item

      respond_to do |format|
        if @item.update(item_params)
          create_image!
          format.html { redirect_to @item, notice: 'Item was successfully updated.' }
          format.json { render :show, status: :ok, location: @item }
        else
          format.html { render :edit }
          format.json { render json: @item.errors, status: :unprocessable_entity }
        end
      end

    else
      @item = Item.new(item_params)
      @item.user_id = current_user.id

      respond_to do |format|
        if @item.save
          create_image!
          format.html { redirect_to @item, notice: 'Item was successfully created.' }
          format.json { render :show, status: :created, location: @item }
        else
          format.html { render :new }
          format.json { render json: @item.errors, status: :unprocessable_entity }
        end
      end

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
      params.require(:item).permit(:name, :description, :is_list, :is_garbage, :is_private, :count, :garbage_reason, :tag_list, :list_id)
    end

    def create_image!
      if params[:item_images] && params[:item_images]['image']
        params[:item_images]['image'].each do |a|
          @item_images = @item.item_images.create!(:image => a)
        end
      end
    end

    def synchronize_with_list
      if @item.is_list
        @item.child_items.each do |i|
          i.update_attribute(:is_private, @item.is_private)
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

end
