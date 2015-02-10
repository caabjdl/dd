require 'zip'
require 'carrierwave/orm/activerecord'

class ExportFile < ActiveRecord::Base
  #mount_uploader :path, FileUploader
  default_scope { order("id desc") }
  
  def self.gzip(sources)
    stringio = Zip::OutputStream::write_buffer do |zio|
      sources.each do |export_file|
        zio.put_next_entry(export_file.name)
        zio.print IO.read(export_file.path)
      end
    end
    stringio.rewind
    binary_data = stringio.sysread
    stringio.close
    return binary_data
  end


  def self.create_file(name, path, extension, type)
    export_file =  ExportFile.new
    export_file.name = name
    export_file.path = path
    export_file.extension = extension
    export_file.file_type = type
    export_file.save
    return export_file
    # if File.exist?(path)
    #   export_file.save
    # end
  end
end
