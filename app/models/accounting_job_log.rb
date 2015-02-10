class AccountingJobLog < ActiveRecord::Base
  belongs_to :accounting_job
  belongs_to :user
end
