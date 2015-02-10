require 'carrierwave/orm/activerecord'
module Wechat
  class WechatMedia < ActiveRecord::Base
    belongs_to :owner, class_name: :User
    belongs_to :worker_job, class_name: 'WorkerJob'
    mount_uploader :media_file, MediaUploader
    store_in_background :media_file

  end
end