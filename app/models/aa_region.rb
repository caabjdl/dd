class AaRegion < ActiveRecord::Base
  belongs_to :aa_vendor


  has_and_belongs_to_many :service_items

end
