class RegistrationsController < Devise::RegistrationsController

  include CarrierwaveBase64Uploader

  prepend_before_action :sign_in_by_json, only: [:update], if: -> {request.format.json?}

  before_action :configure_permitted_parameters_on_sign_up, only: [:sign_up]
  before_action :configure_permitted_parameters_on_update, only: [:update]

  protected

  def update_resource(resource, params)

    if resource.encrypted_password.blank? # || params[:password].blank?
      # provider!=emailの場合
      # update時はcurrent_passwordなしで登録更新できるようにする
      p "2"*20
      params.delete("current_password")

      if params[:email]
        resource.email = params[:email]
      else
        p "6"*20
        params.delete("email")
      end

      if params[:image].present? && is_base64_data?(params[:image])
        p "7"*20
        resource.image = base64_conversion(params[:image])
        params.delete("image")
      end

      if !params[:password].blank? && params[:password] == params[:password_confirmation]
        p "4"*20
        logger.info "Updating password"
        resource.password = params[:password]
        resource.save
      end
      if resource.valid?
        p "5"*20
        resource.update_without_password(params)
      end
      resource.update_without_password(params)
    else
      # provider=emailの場合
      p "!"*20
      p "with email"
      # TODO: パスワードの変更
      pp current_user
      if current_user.present?
        resource.email = current_user.email

        if params[:image].present? && is_base64_data?(params[:image])
          resource.image = base64_conversion(params[:image])
          params.delete("image")
        end

        # resource.name = params["name"]
        # params.delete("name")
        # resource.description = params["description"]
        # params.delete("description")
        # pp resource
        pp params

        params[:email] = current_user.email
      end

      # resource.update_without_password(params)
      resource.update_without_password(params)
    end
  end


  private 

  def configure_permitted_parameters_on_sign_up
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:name, :email, :password, :password_confirmation)
    end
  end 

  def configure_permitted_parameters_on_update
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:name, :email, :password, :password_confirmation, :current_password, :image, :image_cache, :remove_image, :image_for_update, :description)
    end
  end 

  # Devise::RegistrationsControllerはapplicationControllerを通らないっぽい
  # なのでこっちはこっちで自前でトークン認証する
  # sessionControllerも多分同じ...
  def sign_in_by_json
    p "$"*20
    if request.headers['HTTP_X_UID'].present? && request.headers['HTTP_X_ACCESS_TOKEN'].present?
      user = User.find_by(uid: request.headers['HTTP_X_UID'])
      request.env['devise.skip_trackable'] = true
      if Devise.secure_compare(user.try(:token), request.headers['HTTP_X_ACCESS_TOKEN'])
        sign_in user, store: false
      else
        render :json => { "status" => "ssss" }, :status => :unauthorized
      end
    else
      render :json => { "status" => "unou" }, :status => :unauthorized
    end
  end


end
