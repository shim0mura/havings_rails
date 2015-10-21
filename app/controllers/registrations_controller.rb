class RegistrationsController < Devise::RegistrationsController

  before_action :configure_permitted_parameters, only: [:update]
  protected

  def update_resource(resource, params)
    pp resource
    pp params
    p "1"*20
    if resource.encrypted_password.blank? # || params[:password].blank?
      # provider!=emailの場合
      # update時はcurrent_passwordなしで登録更新できるようにする
      p "2"*20
      params.delete("current_password")
      resource.email = params[:email] if params[:email]
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
      resource.update_with_password(params)
    end
  end


  private 
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:name, :email, :password, :password_confirmation, :current_password, :image, :image_cache, :remove_image)
    end
  end 


end
