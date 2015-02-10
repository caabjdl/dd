class AaContractAttachment < ActiveRecord::Base
	self.inheritance_column = nil
	belongs_to :aa_contract
	
	mount_uploader :attachment, ContractUploader
  	store_in_background :attachment
end
