# encoding: utf-8
class Customer < ActiveRecord::Base
  include Sequenable
  include Disable

  # association
  belongs_to :client
  has_many :cars
  has_many :customer_services
  
  sequence :CU
  paginates_per 10

  scope :search, -> (search_text) { joins(:client).where("customers.mobile like :search_text or customers.name like :search_text or customers.driver_license_no like :search_text or clients.name like :search_text ",:search_text=>"%#{search_text}%") unless search_text.blank?}
  default_scope { order("#{table_name}.id desc") }
end