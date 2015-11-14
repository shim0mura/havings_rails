class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # json でのリクエストの場合CSRFトークンの検証をスキップ
  skip_before_action :verify_authenticity_token,     if: -> {request.format.json?}
  # トークンによる認証
  before_action      :authenticate_user_from_token!, if: -> {request.format.json?}

  # ユーザー情報の登録関係はregistrationscontrollerでも行う
  # 両方登録しないといけないっぽい
  before_action :configure_permitted_parameters, if: :devise_controller?

  # http://source.hatenadiary.jp/entry/2014/03/11/104307
  # トークンによる認証
  def authenticate_user_from_token!
    if request.headers['HTTP_X_UID'].present? && request.headers['HTTP_X_ACCESS_TOKEN'].present?
      user = User.find_by(uid: request.headers['HTTP_X_UID'])
      request.env['devise.skip_trackable'] = true
      if Devise.secure_compare(user.try(:token), request.headers['HTTP_X_ACCESS_TOKEN'])
        sign_in user, store: false
      else
        render :json => { "status" => "ssss" }, :status => :unauthorized
      end
    elsif request.path_info == user_registration_path
    elsif request.path_info == user_session_path
    else
      render :json => { "status" => "unou" }, :status => :unauthorized
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << [:name, :email]
    devise_parameter_sanitizer.for(:sign_in) << [:email]
  end

end
