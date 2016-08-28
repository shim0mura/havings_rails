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


      user = User.where(id: timer.user_id).first
      next unless user.present?
      timer.pass_due_time(now)


      DeviceToken.where(user_id: timer.user_id, is_enable: true).each do |device_token|
        if device_token.device_type == DeviceToken::TYPE_ANDROID


          a = HTTParty.post("https://gcm-http.googleapis.com/gcm/send", {
            headers: {
              'Authorization' => "key=AIzaSyAmUXUvErLEMy2ueIjKswdau90c250gJpM",
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            },
              body: {
              'to' => device_token.token,
              'data' => {message: timer.name + "の期限が切れました", id: timer.list_id, type: 0}
            }.to_json
          })



        else
          if Rails.env == 'staging'
            apn = Houston::Client.development
            apn.certificate = File.read("apns_development.pem")
          else
            apn = Houston::Client.production
            apn.certificate = File.read("apns_production.pem")
          end

          notification = Houston::Notification.new(device: device_token.token)
          notification.alert = timer.name + "の期限が切れました"

          notification.badge = JSON.parse(user.notification.unread_events).size
          notification.content_available = true
          notification.custom_data = {item: timer.list_id}

          apn.push(notification)
          if notification.error
            logger.error(notification.error
          end
        end

      end
    end
  end

end
