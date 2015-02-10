class AaContact < ActiveRecord::Base
  belongs_to :aa_vendor
  has_many :aa_regions
end
