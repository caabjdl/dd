class PinganApi::SalvationQueryIn < ActiveRecord::Base
  self.table_name = "pingan_api_salvation_query_in"
  belongs_to :salvation_query_out
  belongs_to :aa_case
end