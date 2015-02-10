class PinganApi::SalvationIn < ActiveRecord::Base
  self.table_name = "pingan_api_salvation_in"
  belongs_to :aa_case
  has_one :salvation_out
end