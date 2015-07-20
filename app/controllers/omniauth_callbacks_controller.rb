class OmniauthCallbacksController < ApplicationController
  def facebook
    omniauth = request.env['omniauth.auth']
    user = User.from_omniauth(omniauth)

    if user.persisted? && user.save
      sign_in_and_redirect(user, event: :authentication)
    else
      session[:omniauth] = omniauth.except('extra')
      redirect_to new_user_registration_path
    end
  end
end