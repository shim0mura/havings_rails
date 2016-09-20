class InquiryMailer < ApplicationMailer
  default to: "tatshimomura@gmail.com" 
  default from: "inquiry@havings.me"

  def received_email(inquiry)
    @inquiry = inquiry
    mail(:subject => 'havingsへの問い合わせ')
  end
end
