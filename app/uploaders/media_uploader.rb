# encoding: utf-8
class MediaUploader < CarrierWave::Uploader::Base
  
  def store_dir
    "clam/#{model.class.name.demodulize.underscore}/#{mounted_as}/#{model.id}"
  end
end