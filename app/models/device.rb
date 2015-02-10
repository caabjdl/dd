class Device < ActiveRecord::Base

  has_one :aa_trailer
  belongs_to :aa_vendor
  
end