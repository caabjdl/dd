class AaVendorAttachment < ActiveRecord::Base
  self.inheritance_column = nil
  belongs_to :aa_vendor

  mount_uploader :attachment, ContractUploader
  store_in_background :attachment
end
