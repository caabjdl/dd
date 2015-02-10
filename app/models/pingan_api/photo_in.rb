class PinganApi::PhotoIn < ActiveRecord::Base
  self.table_name = "pingan_api_photo_in"
  belongs_to :aa_case
  belongs_to :aa_rescue
  belongs_to :phone_out
end