class Permission < ActiveRecord::Base
  include Searchable
  validates_presence_of :subject_class, :action
  validates :action, uniqueness: { scope: :subject_class }

  quick_search :subject_class, :action
  paginates_per 10
end
