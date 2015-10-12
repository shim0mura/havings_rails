module ApplicationHelper

  def notification_html(notification)
    str = notification[:str]

    notification[notification[:type].to_sym].each_with_index do |elm, index|
      if notification[:type] == "timer"
        link_path = item_path(elm[:id])
      end

      # link_toがエスケープを勝手にしてくれるので
      # elm[:name]が<script>alert(1);</script>とか入ってても大丈夫
      link = link_to(elm[:name], link_path)
      str.sub!("__#{notification[:type]}name#{index}__", link)
    end

    return str
  end

end
