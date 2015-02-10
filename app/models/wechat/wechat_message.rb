module Wechat
  class WechatMessage < ActiveRecord::Base
    self.inheritance_column = nil
    paginates_per 20
  end
end