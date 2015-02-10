class PinganApi::OperationIn < ActiveRecord::Base
  self.table_name = "pingan_api_operation_in"
  belongs_to :aa_case
  belongs_to :aa_rescue
  belongs_to :operation_out
end