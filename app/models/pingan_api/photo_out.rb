class PinganApi::PhotoOut < ActiveRecord::Base
  self.table_name = "pingan_api_photo_out"
  belongs_to :aa_case
  belongs_to :aa_rescue
  has_one :phone_in
end