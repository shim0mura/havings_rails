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

  def instagram
    generic_callback( 'instagram' )
  end

  def generic_callback(provider)
    @social_profile = SocialProfile.find_for_oauth(env["omniauth.auth"])

    @user = @social_profile.user || current_user
    if @user.nil?
      # @user = User.create( email: @identity.email || "" )
      @user = User.first_or_create_with_oauth(@social_profile)
    end

    if !@user
      session["devise.#{provider}_data"] = env["omniauth.auth"].except("extra")
      session["tmp_provider_data"] = env["omniauth.auth"].except("extra")
      session["tmp_social_profile_id"] = @identity.id
      redirect_to new_user_registration_url
    elsif @user.persisted?
      @social_profile.update_attribute(:user_id, @user.id)
      # This is because we've created the user manually, and Device expects a
      # FormUser class (with the validations)
      @user = User.find(@user.id)
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.capitalize) if is_navigational_format?
    else
      session["devise.#{provider}_data"] = env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end
end
