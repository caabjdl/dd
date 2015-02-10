# encoding: utf-8
class Api::PinganController < ApplicationController
  protect_from_forgery except: :receive_salvation
  
  def receive_salvation
    business = PinganApi::AssistanceBusiness.new

    data = business.receive_salvation(request.body.read)
    
    aa_case = AaCase.find_by_out_source_no(data.salvation_id)

    if aa_case.nil?
      aa_case = AaCase.new
      aa_case.connected_at = Time.now
      aa_case.data_source = '平安接口'
      if data.salvation_fee_type == "1"
        aa_case.client_service_name = "平安非事故(自费)"
      else
        aa_case.client_service_name = "平安非事故"
      end
      aa_case.out_source_no = data.salvation_id
      aa_case.status = "待平安系统确认"
    end

    aa_case.dep_code = data.dep_code
    aa_case.reporter_name = data.report_name
    aa_case.reporter_telephone = data.report_telephone
    aa_case.customer_name = data.report_name
    aa_case.customer_mobile = data.report_telephone
    #aa_case.salvation_object = data.salvation_object
    aa_case.car_license_no = data.car_mark
    aa_case.car_model = data.car_type
    
    rescue_type_array = OPTIONS["rescue_type"].values_at(*data.salvation_type.split(','))
    #是否取消

    if data.salvation_flag == "2"
      aa_case.status = "等待取消"
      if aa_case.aa_rescue && !aa_case.aa_rescue.status.blank? && aa_case.aa_rescue.status.include?('取消')
        aa_case.status = aa_case.aa_rescue.status
      end
    end

    if rescue_type_array.length > 0
      aa_case.rescue_type = rescue_type_array[0]
      if rescue_type_array.length > 1
        aa_case.memo = "申请服务:" + rescue_type_array.join(",")
      end
    end

    #aa_case. = data.dep_code
    #aa_case. = data.damage_time
    aa_case.from_details = data.damage_place
    # unless data.damage_place.blank?

    #   place_array = data.damage_place.split(/,|-|;/)
    #   aa_case.from_province = place_array[0] if place_array.length > 0
    #   aa_case.from_city = place_array[1] if place_array.length > 1
    #   aa_case.from_region = place_array[2] if place_array.length > 2

    #   #处理直辖市问题
    #   if ["重庆市", "上海市", "北京市", "天津市"].include?(aa_case.from_province)
    #     aa_case.from_region = aa_case.from_city
    #     aa_case.from_city = aa_case.from_province
    #   end
    # end
    #aa_case. = data.insured_name
    unless data.supplement_info.blank?
      if aa_case.memo.nil?
        aa_case.memo = ""
      end
      aa_case.memo += data.supplement_info
    end

    # aa_case. = data.operator_id
    # aa_case. = data.callerno
    # aa_case. = data.salvation_fee_type
    # aa_case. = data.obligate_field
    aa_case.from_longitude = data.gps_x
    aa_case.from_latitude = data.gps_y
    # aa_case. = data.data_source

    aa_case.save(validate: false)

    WebsocketRails[:aa_cases].trigger(:created, aa_case)

    pingan = PinganApi::SalvationIn.new(data.to_hash)
    pingan.aa_case = aa_case
    pingan.save

    back_data = PinganApi::Models::Assistance::SalvationReceiveResponse.new
    back_data.tran_code = data.tran_code
    back_data.bank_code = data.bank_code
    back_data.bk_serial = data.bk_serial
    back_data.pa_acct_datetime = Time.now
    back_data.business_no = ""
    back_data.region_code = "000000"
    back_data.pa_rslt_code = "999999"
    back_data.pa_rslt_mesg = "SUCCESS"
    back_data.salvation_id = data.salvation_id
    back_data.result_time = Time.now
    back_data.salvation_factory_id = "DLJY"

    back_to_pingan = PinganApi::SalvationOut.new(back_data.to_hash)
    back_to_pingan.salvation_in = pingan
    back_to_pingan.aa_case = aa_case
    back_to_pingan.save

    resp = business.receive_salvation_response(back_data)

    # TODO, RETURN AT ONCE WITH STATUS CODE 41
    begin
      #raise Net::ReadTimeout
      PinganApiWorker.new.send_operation_cancel( aa_case.id , data.salvation_flag == "2" ? "41" : "5")
    rescue Exception => e
      Rails.logger.info "send_operation pingan Error #{$!}"
      if e.to_s == Net::ReadTimeout.to_s && data.salvation_flag != "2"
        Notifier.delay.handle_return_pingan_error(data.salvation_id, $!)
        PinganApiWorker.perform_async("send_operation_cancel",aa_case_id: aa_case.id, state: "5" )
      end
    end
    
    #GeoWorker.perform_async(aa_case.id)
    
    #headers["Content-Type"] = "application/xml; charset=GBK"
    render inline: resp
  end

  def query_salvation
    # 先要看看是否已经有这个单号,有的话直接返回
    aa_case = AaCase.find_by_out_source_no_and_data_source(params[:salvation_id], "平安接口")
    if aa_case.nil?
      business = PinganApi::AssistanceBusiness.new
      data = PinganApi::Models::Assistance::SalvationQueryRequest.new
      data.tran_code = "100256"
      data.bank_code = "99840000"
      data.brno = "000000"
      data.tellerno = ""
      data.bk_acct_datetime = Time.now
      data.bk_serial = ""
      data.bk_orgn_sril = ""
      data.bk_tran_chnl = "WEB"
      data.region_code = "999999"
      data.salvation_id = params[:salvation_id]
      data.salvation_factory_id = "DLJY"

      data_out_and_save = PinganApi::SalvationQueryOut.new(data.to_hash)
      data_out_and_save.save

      back_data = business.query_salvation(data)

      if back_data.pa_rslt_code == "999999"
        aa_case = AaCase.new
        aa_case.data_source = '平安接口'
        if back_data.salvation_fee_type == "1"
          aa_case.client_service_name = "平安非事故(自费)"
        else
          aa_case.client_service_name = "平安非事故"
        end
        #aa_case.client_service_name = "平安非事故"
        aa_case.out_source_no = back_data.salvation_id
        aa_case.connected_at = Time.now
        aa_case.reporter_name = back_data.report_name
        aa_case.reporter_telephone = back_data.report_telephone
        aa_case.customer_mobile = back_data.report_telephone
        aa_case.customer_name = back_data.report_name
        #aa_case.salvation_object = back_data.salvation_object
        aa_case.car_license_no = back_data.car_mark
        aa_case.car_model = back_data.car_type
        aa_case.dep_code = back_data.dep_code
        #aa_case. = back_data.damage_time

        rescue_type_array = OPTIONS["rescue_type"].values_at(*back_data.salvation_type.split(','))

        if rescue_type_array.length > 0
          aa_case.rescue_type = rescue_type_array[0]
          if rescue_type_array.length > 1
            aa_case.memo = "申请服务:" + rescue_type_array.join(",")
          end
        end

        aa_case.from_details = back_data.damage_place
        # unless back_data.damage_place.blank?
        #   place_array = back_data.damage_place.split(/,|-|;/)
        #   aa_case.from_province = place_array[0] if place_array.length > 0
        #   aa_case.from_city = place_array[1] if place_array.length > 1
        #   aa_case.from_region = place_array[2] if place_array.length > 2
        #   #处理直辖市问题
        #   if ["重庆市", "上海市", "北京市", "天津市"].include?(aa_case.from_province)
        #     aa_case.from_region = aa_case.from_city
        #     aa_case.from_city = aa_case.from_province
        #   end
        # end
        unless back_data.supplement_info.blank?
          if aa_case.memo.nil?
            aa_case.memo = ""
          end
          aa_case.memo += back_data.supplement_info
        end

        # aa_case. = back_data.insured_name
        # aa_case. = back_data.operator_id
        # aa_case. = back_data.callerno
        # aa_case. = back_data.salvation_fee_type
        # aa_case. = back_data.obligate_field
        aa_case.from_longitude = back_data.gps_x
        aa_case.from_latitude = back_data.gps_y
        # aa_case. = back_data.data_source

        aa_case.save

        #GeoWorker.perform_async(aa_case.id)

        data_back_and_save = PinganApi::SalvationQueryIn.new(back_data.to_hash)
        data_back_and_save.salvation_query_out = data_out_and_save
        data_back_and_save.aa_case = aa_case
        data_back_and_save.save
        redirect_to edit_aa_case_path(aa_case), notice: "已成功从平安获取工单."
      else
        redirect_to request.referer, notice: "无法从平安获取该工单 #{params[:salvation_id]} ,请重新输入有效工单号."
      end
    else
      # 人为约定 当电话洽谈从平安拉单时 需要将超时的单子设置为空
      if aa_case.status == '待平安系统确认'
        aa_case.status = ""
        aa_case.save
      end
      redirect_to edit_aa_case_path(aa_case), notice: "这是一个已经领取过的平安工单."
    end
  end
end
