class PinganApi::SalvationOut < ActiveRecord::Base
  self.table_name = "pingan_api_salvation_out"
  belongs_to :aa_case
  belongs_to :salvation_in
end