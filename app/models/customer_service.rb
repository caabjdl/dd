# encoding: utf-8
class CustomerService < ActiveRecord::Base
  
  # association
  belongs_to :car
  belongs_to :customer
  belongs_to :service_item
  has_many :settlement_institutions
end
