class WelcomeController < ApplicationController

  before_action :authenticate_user!

  def index
    @current_user = current_user
    p current_user
  end

  def home
  end
end
