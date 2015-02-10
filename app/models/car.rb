# encoding: utf-8
class Car < ActiveRecord::Base
  
  # association
  belongs_to :customer
  belongs_to :client
  has_many :customer_services

  paginates_per 10
end
