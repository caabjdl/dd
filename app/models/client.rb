# encoding: utf-8
class Client < ActiveRecord::Base

  has_many :customers
  has_one :client_api_profile
  
  validates_presence_of :no, :name
  validates_uniqueness_of :no, :name

  paginates_per 10
end