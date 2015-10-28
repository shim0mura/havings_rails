class CheckTimerJob < ActiveJob::Base
  queue_as :timer

  def perform(*args)
    # timers = Timer.where(next_due_at: 1.hour.ago..Time.now)
    now = Time.now
    timers = Timer.where(next_due_at: 3.day.ago..Time.now)
    timers.each do |timer|

      # 1回限りのタスクで既に通知済みのも取得してしまうので
      # それについては飛ばす
      next if !timer.is_repeating && timer.over_due_from

      timer.pass_due_time(now)

      # TODO: push通知の処理とメールの処理
      # この処理が行われた瞬間に通知するタイプと
      # X日オーバー時点でのリマインドとして通知するタイプと
      # X日前時点での予めリマインドとして通知するタイプの3つ？
      # 最後のタイプはいらないと思うけど…
    end
  end

end
