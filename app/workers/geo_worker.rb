require 'net/http'
require 'json'

class GeoWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5

  COORDTYPE = {
    "通用接口" => "1",
    "平安接口" => "gcj02ll",
    "手动创建" => "bd09ll"
  }
  
  def perform(aa_case_id)
    aa_case = AaCase.find_by_id(aa_case_id)
    unless aa_case.nil?
      Sidekiq.logger.info "任务 #{aa_case.no} 解析地址 at #{Time.now}"
      if (aa_case.from_latitude.blank? || aa_case.from_longitude.blank?)
        # 如果省/市有数据,就不需要解析
        if aa_case.from_province.blank? || aa_case.from_city.blank?
          from_location = GeoApi.get_location_from_string(aa_case.from_details)
          Sidekiq.logger.info "任务 #{aa_case.no} 地址拆分结果 #{from_location.inspect} at #{Time.now}"
          unless from_location.nil?
            aa_case.from_province = from_location["province"]
            aa_case.from_city = from_location["city"]
            aa_case.from_region = from_location["region"]
          end
        end
      else
        from_location = GeoApi.get_location_from_coordinate(aa_case.from_latitude, aa_case.from_longitude, COORDTYPE[aa_case.data_source])
        unless from_location.nil?
          Sidekiq.logger.info "任务 #{aa_case.no} 地址解析结果 #{from_location.inspect} at #{Time.now}"
          aa_case.from_province = from_location["province"]
          aa_case.from_city = from_location["city"]
          aa_case.from_region = from_location["region"]
          aa_case.from_coordinate_address = from_location["detail"]
        end
      end

      # to_location = GeoApi.get_location_from_coordinate(aa_case.to_latitude, aa_case.longitude, COORDTYPE[aa_case.data_source])
      # unless to_location.nil?
      #   aa_case.to_province = to_location["province"]
      #   aa_case.to_city = to_location["city"]
      #   aa_case.to_region = to_location["region"]
      #   aa_case.to_details = to_location["detail"]
      #   aa_case.to_coordinate_address = to_location["detail"]
      # end
      aa_case.save(validate: false)
      AutoAssignWorker.perform_async
    end
  end
end