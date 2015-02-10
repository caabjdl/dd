# encoding: utf-8
class ClientService < ActiveRecord::Base
  include Searchable
  include Disable

  # validate
  validates_uniqueness_of :name
  validates_presence_of :name
  has_many :settlement_institutions
  paginates_per 10
  quick_search :name
end