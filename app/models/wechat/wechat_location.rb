module Wechat
  class WechatLocation < ActiveRecord::Base
    belongs_to :user
    belongs_to :worker_job
  end
end
