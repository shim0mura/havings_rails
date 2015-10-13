class TimersController < ApplicationController

  before_action :authenticate_user!
  before_action :set_timer, only: [:update, :destroy, :done]

  def index
  end

  def create
    # NOTICE: 時刻の扱い
    # MySQL上ではnext_due_atはutcになってるけど
    # ARで扱うときはJSTにしてくれてるので今のところは問題ない
    # http://qiita.com/joker1007/items/2c277cca5bd50e4cce5e
    # http://qiita.com/jnchito/items/cae89ee43c30f5d6fa2c

    if over_timer_count?(params[:timer][:list_id])
      render json: { }, status: :unprocessable_entity 
      return
    end

    @timer = Timer.new(timer_params)
    @timer.user_id = current_user.id
    set_timer_props
    
    if @timer.save
      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

  def done
    if @timer.is_repeating
      @timer.next_due_at = @timer.get_next_due_at_when_task_done
      props = JSON.parse(@timer.properties)
      props["start_at"] = Time.now.to_s
      @timer.properties = props.to_json
    else
      @timer.is_active = false
    end

    @timer.over_due_from = nil

    if @timer.save
      Event.create(
        event_type: :done_task,
        acter_id: current_user.id,
        related_id: @timer.id,
        properties: {
          done_date: Time.now
        }
      )
      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

  def update

    @timer.name = params[:timer][:name]
    @timer.is_repeating = params[:timer][:is_repeating]
    @timer.over_due_from = nil
    set_timer_props

    if @timer.next_due_at < Time.now
      render json: { }, status: :unprocessable_entity 
      return
    end

    if @timer.save
      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end

  end

  def destroy
    @timer.is_deleted = true
    @timer.is_active = false
    @timer.events.each{|e|e.disable}
    if @timer.save
      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

  private

    def set_timer
      @timer = Timer.find(params[:id])
    end

    def set_timer_props
      @timer.next_due_at = Time.parse(params[:timer][:next_due_at])
      properties = params[:timer][:properties]
      properties[:is_repeating] = @timer.is_repeating
      @timer.properties = params[:timer][:properties].to_json
    end

    def timer_params
      params.require(:timer).permit(:name, :list_id, :is_repeating)
    end

    def over_timer_count?(list_id)
      Timer.where(list_id: list_id, user_id: current_user.id).count >= Timer::MAX_COUNT_PER_LIST
    end
end
