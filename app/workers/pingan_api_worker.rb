class PinganApiWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3
  
  def perform(method_name, options = {})
    case method_name
    when "send_operation"
      send_operation(options["aa_rescue_id"], options["stats_array"])
    when "query_salvation"
      query_salvation()
    when "send_operation_cancel"
      send_operation_cancel(options["aa_case_id"],options["state"])
    else
    end
  end

  def send_operation(aa_rescue_id, stats_array)
    business = PinganApi::AssistanceBusiness.new
    # aa_rescue = AaRescue.new
    # aa_rescue.id = aa_rescue_id
    # aa_rescue.reload
    aa_rescue = AaRescue.find_by_id(aa_rescue_id)
    unless aa_rescue.nil?
      # try to fix data exprie bug
      aa_rescue.reload
      stats_array.each do |stats|
        data = prepare_operation_model_for_pingan(aa_rescue)
        data.salvation_state = stats
        data_out_and_save = PinganApi::OperationOut.new(data.to_hash)
        data_out_and_save.aa_case = aa_rescue.aa_case
        data_out_and_save.aa_rescue = aa_rescue
        data_out_and_save.save

        back_data = business.send_operation(data)

        data_back_and_save = PinganApi::OperationIn.new(back_data.to_hash)
        data_back_and_save.aa_case = aa_rescue.aa_case
        data_back_and_save.aa_rescue = aa_rescue
        data_back_and_save.operation_out = data_out_and_save
        data_back_and_save.save
      end
    end
  end

  def send_operation_cancel(aa_case_id, state)
    aa_case = AaCase.find_by_id(aa_case_id)
    p aa_case
    business = PinganApi::AssistanceBusiness.new
    # aa_rescue = AaRescue.new
    # aa_rescue.id = aa_rescue_id
    # aa_rescue.reload
      # try to fix data exprie bug
    data = PinganApi::Models::Assistance::OperationSendRequest.new
    data.tran_code = "100231"
    data.bank_code = "99840000"
    data.salvation_id = aa_case.out_source_no
    data.brno = "000000"
    data.tellerno = ""
    data.bk_acct_datetime = Time.now
    data.bk_serial = ""
    data.bk_orgn_sril = ""
    data.bk_tran_chnl = "WEB"
    data.region_code = "999999"
    data.malfunction_type = OPTIONS["rescue_reason"].key(aa_case.rescue_reason)
    data.salvation_type_act = OPTIONS["rescue_type_actual"].key(aa_case.rescue_type)
    data.begin_point = aa_case.from_address
    data.salvation_fee_type = aa_case.get_salvation_fee_type
    
    data.date_connecting = nil
    data.date_dispatch = nil
    data.date_arrive = nil
    data.date_finished = nil
    data.drag_distance = nil
    data.salvation_result = ""
    data.quit_reason = "AO"
    data.other_info = aa_case.updated_at.strftime('%y-%m-%d %H:%M:%S:%L')
    data.salvation_fee = 0
    #data.insured_status = ""
    #data.end_point = "#{aa_rescue.aa_case.to_province},#{aa_rescue.aa_case.to_city},#{aa_rescue.aa_case.to_region},#{aa_rescue.aa_case.to_details}"
    #data.salvation_fee_pt = ""
    #data.salvation_object_aa = ""
    data.salvation_help_time = Time.now
    data.salvation_person_name = ""
    data.salvation_person_telno = ""
    data.salvation_intending_time = nil
    data.salvation_person_workno = ""
    data.act_gps_x = aa_case.from_longitude
    data.act_gps_y = aa_case.from_latitude
    data.act_salvation_place = aa_case.from_address
    data.salvation_factory_id = "DLJY"
    data.salvation_person_mobile_no = ""
    
    data.salvation_state = state
    data_out_and_save = PinganApi::OperationOut.new(data.to_hash)
    data_out_and_save.aa_case = aa_case
    data_out_and_save.aa_rescue = nil
    data_out_and_save.save

    back_data = business.send_operation(data)

    data_back_and_save = PinganApi::OperationIn.new(back_data.to_hash)
    data_back_and_save.aa_case = aa_case
    data_back_and_save.aa_rescue = nil
    data_back_and_save.operation_out = data_out_and_save
    data_back_and_save.save

    if data_back_and_save.pa_rslt_code != '999999' && state != "5"
      aa_case.status = "等待取消"
      if aa_case.aa_rescue && !aa_case.aa_rescue.status.blank? && aa_case.aa_rescue.status.include?('取消')
        aa_case.status = aa_case.aa_rescue.status
      end
    elsif data_back_and_save.pa_rslt_code == '999999' && state == "5"
      aa_case.status = ""
    end
    aa_case.save

  end

  def send_photo(aa_case_id)
    aa_case = AaCase.find_by_id(aa_case_id)

    business = PinganApi::AssistanceBusiness.new
    data = PinganApi::Models::Assistance::UploadPhotoSendRequest.new
    data.tran_code = "100285"
    data.bank_code = "99940000"
    data.salvation_id = aa_case.out_source_no
    data.salvation_company_id = "caa"
    data.brno = "000000"
    data.tellerno = ""
    data.bk_acct_datetime = Time.now
    data.bk_serial = ""
    data.bk_orgn_sril = ""
    data.bk_tran_chnl = "WEB"
    data.region_code = "999999"
    data.car_mark = aa_case.car_license_no

    data.photo1_shot_date = Time.now
    data.photo1_uploaded_date = Time.now
    data.photo1_name = "DAL_"+aa_case.out_source_no+"_"+"001.jpg"

    data.photo2_shot_date = Time.now
    data.photo2_uploaded_date = Time.now
    data.photo2_name = "DAL_"+aa_case.out_source_no+"_"+"002.jpg"
    p data
    
    data_out_and_save = PinganApi::PhotoOut.new(data.to_hash)
    data_out_and_save.aa_case = aa_case
    data_out_and_save.save

    back_data = business.send_photo(data)

    data_back_and_save = PinganApi::PhotoIn.new(back_data.to_hash)
    data_back_and_save.aa_case = aa_case
    data_back_and_save.photo_out = data_out_and_save
    data_back_and_save.save

  end

  def prepare_operation_model_for_pingan(aa_rescue)
    data = PinganApi::Models::Assistance::OperationSendRequest.new
    data.tran_code = "100231"
    data.bank_code = "99840000"
    data.salvation_id = aa_rescue.aa_case.out_source_no
    data.brno = "000000"
    data.tellerno = ""
    data.bk_acct_datetime = Time.now
    data.bk_serial = ""
    data.bk_orgn_sril = ""
    data.bk_tran_chnl = "WEB"
    data.region_code = "999999"
    data.malfunction_type = OPTIONS["rescue_reason"].key(aa_rescue.aa_case.rescue_reason)
    data.salvation_type_act = OPTIONS["rescue_type_actual"].key(aa_rescue.aa_case.rescue_type)
    data.begin_point =  aa_rescue.aa_case.from_address
    # data.salvation_fee_type = (!aa_rescue.fee.nil? && aa_rescue.fee > 0) ? "1" : "0"
    data.salvation_fee_type = aa_rescue.aa_case.get_salvation_fee_type

    data.date_connecting = aa_rescue.contacted_at
    data.date_dispatch = aa_rescue.dispatched_at
    data.date_arrive = aa_rescue.arrived_at
    data.date_finished = aa_rescue.completed_at
    data.drag_distance = aa_rescue.distance_drag
    data.salvation_result = ""
    data.quit_reason = OPTIONS["rescue_cancel_reason"].key(aa_rescue.cancel_reason)
    data.other_info = aa_rescue.updated_at.strftime('%y-%m-%d %H:%M:%S:%L')
    data.salvation_fee = aa_rescue.fee
    #data.insured_status = ""
    #data.end_point = "#{aa_rescue.aa_case.to_province},#{aa_rescue.aa_case.to_city},#{aa_rescue.aa_case.to_region},#{aa_rescue.aa_case.to_details}"
    #data.salvation_fee_pt = ""
    #data.salvation_object_aa = ""
    data.salvation_help_time = Time.now
    data.salvation_person_name = aa_rescue.aa_worker_name
    data.salvation_person_telno = aa_rescue.aa_worker_phone
    data.salvation_intending_time = aa_rescue.plan_arrive_at
    data.salvation_person_workno = ""
    data.act_gps_x = aa_rescue.aa_case.from_longitude
    data.act_gps_y = aa_rescue.aa_case.from_latitude
    data.act_salvation_place = aa_rescue.aa_case.from_address
    data.salvation_factory_id = "DLJY"
    data.salvation_person_mobile_no = aa_rescue.photo_phone.blank? ? aa_rescue.aa_worker_phone : aa_rescue.photo_phone
    data
  end

  def query_salvation(query_out_id)
  end

end