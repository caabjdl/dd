require 'net/http'
require 'singleton'
module Wechat
  class WechatService
    include Singleton

    def send_text(url,open_id,content)
      # Wechat::WechatService.instance.send_text
      uri = URI(url)
      Rails.logger.info uri
      res = Net::HTTP.post_form(uri, 'open_id' => open_id, 'content' => content)
    end
  end
end