module ControllerMacros
  # def login_admin
  #   before(:each) do
  #     @request.env["devise.mapping"] = Devise.mappings[:admin]
  #     sign_in FactoryGirl.create(:admin) # Using factory girl as an example
  #   end
  # end

  def login_user
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      @current_user = FactoryGirl.create(:user)
      # or set a confirmed_at inside the factory. Only necessary if you are using the "confirmable" module
      # user.confirm!
      sign_in @current_user
    end
  end
end
