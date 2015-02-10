class VisitHistory < ActiveRecord::Base
  include Searchable
  quick_search :item_id, :item_type, :action
  
  belongs_to :user
  paginates_per 20
  default_scope { order("#{table_name}.id desc") }
end
