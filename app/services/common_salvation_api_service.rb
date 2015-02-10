# encoding: utf-8
require 'singleton'

class CommonSalvationApiService
  include Singleton

  def receive_salvation(data)
    data_back = Hash.new
    unless data["customer_name"].blank? || data["customer_mobile"].blank? || data["cid"].blank?
      profile = ClientApiProfile.find_by_cid(data["cid"])
      unless profile.nil? || profile.disabled
        aa_case = AaCase.find_by_out_source_no_and_client_service_name(data["no"], profile.client_service_name)
        if (data["no"].blank? || (!data["no"].blank? && aa_case.nil?))
          aa_case = AaCase.new
          set_aa_case(aa_case, data)
          aa_case.client_service_name = profile.client_service_name
          aa_case.customer_open_id = data["open_id"] unless data["open_id"].blank?
          if aa_case.save
            GeoWorker.perform_async(aa_case.id)
            data_back["return_code"] = "1"
            data_back["return_message"] = "救援创建成功."
            data_back["case_id"] = aa_case.no
          else
            data_back["return_code"] = "99"
            data_back["return_message"] = "数据不完整. #{aa_case.errors.inspect}"
            data_back["case_id"] = nil
          end
        else
          aa_case =  AaCase.find_by_out_source_no_and_client_service_name(data["no"], profile.client_service_name)
          unless aa_case.nil?
            aa_case = set_aa_case(aa_case, data)
            if aa_case.save
              GeoWorker.perform_async(aa_case.id)
              data_back["return_code"] = "2"
              data_back["return_message"] = "救援更新成功."
              data_back["case_id"] = aa_case.no
            else
              data_back["return_code"] = "99"
              data_back["return_message"] = "数据不完整. #{aa_case.errors.inspect}"
              data_back["case_id"] = nil
            end
          else
            data_back["return_code"] = "99"
            data_back["return_message"] = "找不到该编号的救援."
            data_back["case_id"] = nil
          end
        end
      else
        data_back["return_code"] = "99"
        data_back["return_message"] = "CID不合法或者已被禁用."
        data_back["case_id"] = nil
      end
    else
      data_back["return_code"] = "99"
      data_back["return_message"] = "数据不完整."
      data_back["case_id"] = nil
    end

    return data_back
  end

  # 提供callback入口,为了执行效率,具体执行封装到salvation_callback_execute,通过异步方式执行,对调用方隐藏异步接口
  def salvation_callback(aa_case)
    CommonApiWorker.perform_async(aa_case.id)
  end

  def salvation_callback_execute(aa_case_id)
    aa_case = AaCase.find_by_id(aa_case_id)
    api = ClientApiProfile.find_by_client_service_name(aa_case.client_service_name)
    Sidekiq.logger.info "找到API配置/API配置为空:#{api.nil?}/API已被禁用#{api.disabled}/CALLBACK地址为空#{api.callback.blank?} at #{Time.now}"
    unless api.nil? || api.disabled || api.callback.blank?
      data_back = Hash.new
      data_back["id"] = aa_case.no
      if !aa_case.aa_rescue.nil? && !aa_case.aa_rescue.status.blank?
        case aa_case.aa_rescue.status
          when "已回拨" then data_back["status_name"] = "已电话联系"
          when "已调度救援中" then data_back["status_name"] = "已调派车辆"
          when "已完成" then data_back["status_name"] = "已完成"
          when "取消无空驶", "取消有空驶" then data_back["status_name"] = "已取消"
        end
      else
        data_back["status_name"] = "已电话联系"
      end
      data_back["status_code"] = { "已电话联系" => "10", "已调派车辆" => "20", "已到达现场" => "30", "已完成" => "00", "已取消" => "99" }[data_back["status_name"]]
      data_back["changed_at"] = aa_case.aa_rescue.updated_at.strftime("%Y-%m-%d %H:%M:%S")

      # data_back["case_id"] = aa_case.no
      # data_back["status"] = aa_case.aa_rescue.status if aa_case.aa_rescue
      # data_back["time"] = Time.now
      # data_back["rescue_type"] = aa_case.rescue_type
      # data_back["memo"] = aa_case.memo
      # data_back["description"] = ""
      # if aa_case.aa_rescue && aa_case.aa_rescue.aa_case_logs.last
      #   data_back["description"] = aa_case.aa_rescue.aa_case_logs.last.content
      # end
      

      uri = URI(api.callback)

      request = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
      request.body = data_back.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request(request)
      Sidekiq.logger.info "发送到:#{api.callback} at #{Time.now}"
      Sidekiq.logger.info "发送:#{request.body} at #{Time.now}"
      Sidekiq.logger.info "返回:#{response.body} at #{Time.now}"
    end
  end

  def delete_salvation(data)
    data_back = Hash.new
    data_back["return_code"] = "1"
    data_back["return_message"] = "删除成功."
    data_back["case_id"] = nil
    return data_back
  end

  def query_salvation
    
  end



  private

  def set_aa_case(aa_case, data)
    aa_case.out_source_no = data["no"]
    aa_case.customer_name = data["customer_name"]
    aa_case.customer_mobile = data["customer_mobile"]
    aa_case.car_license_no = data["car_license_no"]
    aa_case.car_color = data["car_color"]
    aa_case.car_model = data["car_model"]
    aa_case.car_vin = data["car_vin"]
    aa_case.rescue_type = data["rescue_type"]
    aa_case.from_latitude = data["latitude"]
    aa_case.from_longitude = data["longitude"]
    aa_case.from_details = data["location"]
    aa_case.data_source = "通用接口"
    aa_case.connected_at = Time.now
    #aa_case. = data["no"]
    #aa_case. = data["accepted_at"]
    aa_case.memo = data["memo"]
    aa_case
  end  
end