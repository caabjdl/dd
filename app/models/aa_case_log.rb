class AaCaseLog < ActiveRecord::Base
  belongs_to :aa_case
  belongs_to :aa_rescue
  belongs_to :logger, class_name: "User"
  validates_presence_of :content
  validates_presence_of :eta, :if => Proc.new{|m| m.status == '已调派' }
 
end