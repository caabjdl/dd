class WechatMessagesController < ApplicationController
  before_action :authenticate_user!
  def index
    @messages = Wechat::WechatMessage.all.order("id desc").page(params[:page])
  end
end