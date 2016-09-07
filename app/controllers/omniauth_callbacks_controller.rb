class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def instagram
    generic_callback( 'instagram' )
  end

  def facebook
    generic_callback( 'facebook' )
  end

  def twitter
    generic_callback( 'twitter' )
  end

  def hatena
    generic_callback( 'hatena' )
  end

  def generic_callback(provider)
    p "#"*20
    p request.env['omniauth.origin']
    @social_profile = SocialProfile.find_for_oauth(env["omniauth.auth"])
    pp @social_profile

    @user = @social_profile.user || current_user
    pp @user
    if @user.nil?
      # @user = User.create( email: @identity.email || "" )
      @user = User.first_or_create_with_oauth(@social_profile)
    end

    p @user
    p @user.persisted?
    p request.env['omniauth.origin'] == "android"
    p request.env['omniauth.origin']


    if !@user
      p "'"*20
      session["devise.#{provider}_data"] = env["omniauth.auth"].except("extra")
      session["tmp_provider_data"] = env["omniauth.auth"].except("extra")
      session["tmp_social_profile_id"] = @identity.id
      redirect_to new_user_registration_url
    elsif @user.persisted? && request.env['omniauth.origin'] == "android"
      # https://github.com/intridea/omniauth/wiki/Saving-User-Location
      # http://blog.yasuoza.com/2012/08/16/devise-omniauth-facebook/
      # androidからきた時のcallback指定
      p "$"*20
      store_location_for(:user, oauth_android_callback_path(token: @user.token, uid: @user.uid, userid: @user.id))
      p session["user_return_to"]
      @social_profile.update_attribute(:user_id, @user.id)
      # sign_in @user, event: :authentication
      sign_in_and_redirect @user, event: :authentication
    elsif @user.persisted? && request.env['omniauth.origin'] == "ios"
      p "("*20
      store_location_for(:user, oauth_ios_callback_path(token: @user.token, uid: @user.uid, userid: @user.id))
      p session["user_return_to"]
      @social_profile.update_attribute(:user_id, @user.id)
      # sign_in @user, event: :authentication
      sign_in_and_redirect @user, event: :authentication
    
    elsif @user.persisted?
      p "="*20
      @social_profile.update_attribute(:user_id, @user.id)
      # This is because we've created the user manually, and Device expects a
      # FormUser class (with the validations)
      @user = User.find(@user.id)
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.capitalize) if is_navigational_format?
    else
      p "7"*20
      session["devise.#{provider}_data"] = env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end
end
