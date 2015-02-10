require 'csv'


module ExportCsv
  extend ActiveSupport::Concern
  module ClassMethods
    def csv_file
      CSV.generate do |csv|
        csv << column_names
        all.each do |product|
          csv << product.attributes.values_at(*column_names)
        end
      end
    end
    
  end
end