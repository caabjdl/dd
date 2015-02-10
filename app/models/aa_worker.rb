class AaWorker < ActiveRecord::Base
  belongs_to :aa_vendor
  belongs_to :user
  has_one :aa_trailer
  validates_presence_of :id_no, :name, :mobile
end
