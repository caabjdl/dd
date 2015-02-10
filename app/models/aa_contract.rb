#require 'carrierwave/orm/activerecord'
class AaContract < ActiveRecord::Base
  include Searchable
  
  quick_search :no, :status
  validates_presence_of :no, :from, :to
  validates_uniqueness_of :no

  belongs_to :aa_vendor
  has_many :aa_contract_attachments

  
  #accepts_nested_attributes_for :aa_vendor, allow_destroy: true

  accepts_nested_attributes_for :aa_contract_attachments, allow_destroy: true


  paginates_per 10

  mount_uploader :attachment, ContractUploader
  store_in_background :attachment


end
