class TimersController < ApplicationController

  before_action :authenticate_user!
  before_action :set_timer, only: [:update, :destroy, :done, :do_later, :end_timer]
  before_action :can_edit?, only: [:update, :destroy, :done, :do_later, :end_timer]

  def index
    @timers = Timer
      .includes(:list)
      .where(user_id: current_user.id)
      .order(over_due_from: :desc, next_due_at: :desc)

    @timers = @timers.map{|timer| json_rendered_timer(timer)}

    render json: @timers
  end

  def create
    # NOTICE: 時刻の扱い
    # MySQL上ではnext_due_atはutcになってるけど
    # ARで扱うときはJSTにしてくれてるので今のところは問題ない
    # http://qiita.com/joker1007/items/2c277cca5bd50e4cce5e
    # http://qiita.com/jnchito/items/cae89ee43c30f5d6fa2c

    @timer = Timer.new(timer_params)
    @timer.user_id = current_user.id
    set_timer_props

    if over_timer_count?(params[:timer][:list_id])
      render json: {errors: {"このリストではこれ以上タイマーを作成できません" => ["."]}}, status: :unprocessable_entity 
      return
    end

    if @timer.save
      # render json: { status: :ok }

      render json: json_rendered_timer(@timer)
    else
      render json: {errors: @timer.errors}, status: :unprocessable_entity
    end
  end

  # already_doneの場合もこのメソッドで処理
  # already_doneの場合は行った時間を
  # params[:timer][:done_at]で指定
  def done

    if @timer.is_repeating
      @timer.latest_calc_at = @timer.over_due_from.present? ? Time.now : @timer.next_due_at
      if params[:timer][:next_due_at].present?
        @timer.next_due_at = Time.at(Item.get_timestamp_without_millis(params[:timer][:next_due_at]))
      else
        @timer.next_due_at = @timer.get_next_due_at_when_task_done
      end
    else
      @timer.is_active = false
    end

    @timer.over_due_from = nil

    begin
      ActiveRecord::Base.transaction do

        @timer.save!
        done_date = params[:timer][:done_at].present? ? Time.at(Item.get_timestamp_without_millis(params[:timer][:done_at])) : Time.now

        Event.create!(
          event_type: :done_task,
          acter_id: current_user.id,
          related_id: @timer.id,
          properties: {
            done_date: done_date
          }.to_json
        )
      end

      render json: json_rendered_timer(@timer)
    rescue => e
      logger.error("timer_done_failed, item_id: #{@item.id}, timer_id: #{@timer.id}, #{e}, #{e.backtrace}")
      render json: @item.errors, status: :unprocessable_entity
    end
  end

  def do_later
    @timer.next_due_at = Time.at(Item.get_timestamp_without_millis(params[:timer][:next_due_at]))
    @timer.over_due_from = nil
    @timer.latest_calc_at = Time.now

    begin
      ActiveRecord::Base.transaction do
        @timer.save!
      end
      render json: json_rendered_timer(@timer)
    rescue => e
      logger.error("timer_do_later_failed, item_id: #{@item.id}, timer_id: #{@timer.id}, #{e}, #{e.backtrace}")
      render json: {errors: @timer.errors}, status: :unprocessable_entity
    end

  end

  def update

    @timer.name = params[:timer][:name]
    @timer.is_repeating = params[:timer][:is_repeating]
    prev_next_due_at = @timer.next_due_at
    set_timer_props
    @timer.over_due_from = nil if @timer.next_due_at != prev_next_due_at


    begin
      ActiveRecord::Base.transaction do
        @timer.save!
      end
      render json: json_rendered_timer(@timer)
    rescue => e
      logger.error("timer_update_failed, item_id: #{@item.id}, timer_id: #{@timer.id}, #{e}, #{e.backtrace}")
      render json: {errors: @timer.errors}, status: :unprocessable_entity
    end

  end

  def destroy
    @timer.is_deleted = true
    @timer.is_active = false
    begin
      ActiveRecord::Base.transaction do
        @timer.save!(validate: false)
        @timer.events.each{|e|e.disable}
      end
      render json: json_rendered_timer(@timer)
    rescue => e
      logger.error("timer_destroy_failed, item_id: #{@item.id}, timer_id: #{@timer.id}, #{e}, #{e.backtrace}")
      render json: {errors: @timer.errors}, status: :unprocessable_entity
    end
  end

  def end_timer
    @timer.is_deleted = false
    @timer.is_active = false
    pp @timer
    begin
      ActiveRecord::Base.transaction do
        @timer.save!(validate: false)
      end
      render json: json_rendered_timer(@timer)
    rescue => e
      logger.error("timer_end_failed, item_id: #{@item.id}, timer_id: #{@timer.id}, #{e}, #{e.backtrace}")
      render json: {errors: @timer.errors}, status: :unprocessable_entity
    end

  end

  private

    def set_timer
      @timer = Timer.find(params[:id])
    end

    def can_edit?
      unless @timer.user_id == current_user.id
        render json: { }, status: 500
        return
      end
    end

    def set_timer_props
      if request.format.json?
        @timer.next_due_at = Time.at(Item.get_timestamp_without_millis(params[:timer][:next_due_at]))
        @timer.latest_calc_at = Time.at(Item.get_timestamp_without_millis(params[:timer][:latest_calc_at])) unless @timer.id.present?
        properties = @timer.properties ? JSON.parse(@timer.properties) : {}
        properties[:is_repeating] = @timer.is_repeating
        properties[:repeat_by] = params[:timer][:repeat_by]
        properties[:start_at] = Time.now.to_s unless properties["start_at"]
        properties[:notice_hour] = params[:timer][:notice_hour].present? ? params[:timer][:notice_hour] : @timer.next_due_at.hour
        properties[:notice_minute] = params[:timer][:notice_minute].present? ? params[:timer][:notice_minute] : @timer.next_due_at.min

        properties[:repeat_by_day] = {}
        properties[:repeat_by_day][:month_interval] = params[:timer][:repeat_month_interval]
        properties[:repeat_by_day][:day] = params[:timer][:repeat_day_of_month]
        properties[:repeat_by_week] = {}
        properties[:repeat_by_week][:week] = params[:timer][:repeat_week]
        properties[:repeat_by_week][:day_of_week] = params[:timer][:repeat_day_of_week]
        @timer.properties = properties.to_json
      else
        @timer.next_due_at = Time.parse(params[:timer][:next_due_at])
        properties = params[:timer][:properties]
        properties[:is_repeating] = @timer.is_repeating
        @timer.properties = params[:timer][:properties].to_json
      end
    end

    def timer_params
      params.require(:timer).permit(:name, :list_id, :is_repeating)
    end

    def over_timer_count?(list_id)
      Timer.where(list_id: list_id, user_id: current_user.id).count >= Timer::MAX_COUNT_PER_LIST
    end

    def json_rendered_timer(timer)
      # apiでjson形式で送るとき、propertiesの中身をそのままでは表現できないので
      # バラしてちょっと違う形に変形する
      rendered_timer = timer.to_light
      rendered_timer[:id] = timer.id
      rendered_timer[:list_id] = timer.list_id
      rendered_timer[:list_name] = timer.list.name rescue nil
      rendered_timer[:is_active] = timer.is_active
      rendered_timer[:is_deleted] = timer.is_deleted
      properties = JSON.parse(timer.properties)
      rendered_timer[:next_due_at] = timer.next_due_at
      rendered_timer[:latest_calc_at] = timer.latest_calc_at
      rendered_timer[:over_due_from] = timer.over_due_from
      rendered_timer[:notice_hour] = properties["notice_hour"] ? properties["notice_hour"].to_i : timer.next_due_at.hour
      rendered_timer[:notice_minute] = properties["notice_minute"] ? properties["notice_minute"].to_i : timer.next_due_at.min
      rendered_timer[:repeat_by] = properties["repeat_by"].to_i
      rendered_timer[:repeat_month_interval] = properties["repeat_by_day"]["month_interval"].to_i
      rendered_timer[:repeat_day_of_month] = properties["repeat_by_day"]["day"].to_i
      rendered_timer[:repeat_week] = properties["repeat_by_week"]["week"].to_i
      rendered_timer[:repeat_day_of_week] = properties["repeat_by_week"]["day_of_week"].to_i

      return rendered_timer
    end
end
