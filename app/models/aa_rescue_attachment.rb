#encoding: utf-8
class AaRescueAttachment < ActiveRecord::Base
  belongs_to :aa_rescue
  mount_uploader :attachment, AaRescueAttachmentUploader
  store_in_background :attachment
end