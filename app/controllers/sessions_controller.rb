class SessionsController < Devise::SessionsController
  def destroy
    UserOnlineManager.set_offline(current_user)
    super
  end
end