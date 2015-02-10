# encoding: utf-8
class Events::UsersController < WebsocketRails::BaseController

  def change_status
    UserOnlineManager.set_status(current_user, message[:status]) unless current_user.nil?
  end

  def connected
    UserOnlineManager.connected(current_user) unless current_user.nil?
  end

  def disconnected
    UserOnlineManager.disconnected(current_user) unless current_user.nil?
  end
end