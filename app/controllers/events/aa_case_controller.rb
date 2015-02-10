#encoding: utf-8
class Events::AaCaseController < WebsocketRails::BaseController
  before_filter :only => :created do
    puts "new aa case was called"
  end

  def initialize_session
    # perform application setup here
    controller_store[:message_count] = 0
  end

  def created
    message = "新订单被创建~~"
    send_message :created, message, :namespace => 'aa_case'
  end
end