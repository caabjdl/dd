class PinganApi::OperationOut < ActiveRecord::Base
  self.table_name = "pingan_api_operation_out"
  belongs_to :aa_case
  belongs_to :aa_rescue
  has_one :operation_in
end