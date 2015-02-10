# encoding: utf-8
class ServiceItem < ActiveRecord::Base
  include Searchable

  # association
  has_and_belongs_to_many :aa_regions

  # validate
  validates_presence_of :name, :no, :category
  validates_uniqueness_of :name, :no

  quick_search :category, :name
end