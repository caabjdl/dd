class SmsApiWorker
  include Sidekiq::Worker
  #sidekiq_options :retry => 1

  def perform(method,aa_case_id,phone=nil)
    aa_case = AaCase.find_by_id(aa_case_id)
    sms = self.send(method,aa_case)
    Services::SmsService.instance.send_sms(sms)
  end

  def remind_worker(aa_case)
    address = aa_case.from_details.blank? ? aa_case.from_coordinate_address : aa_case.from_details
    content = OPTIONS["sms_template"]["remind_worker"] % { :customer_name => aa_case.customer_name, :type => aa_case.rescue_type,
      :no => aa_case.no, :car_model => aa_case.car_model, :car_color => aa_case.car_color, :memo => aa_case.memo,
      :car_license_no => aa_case.car_license_no, :from_details => address, :customer_mobile => aa_case.customer_mobile  }
    sms =  Sms::Out.new(content: content, mobile:aa_case.aa_rescue.worker_jobs.enabled.first.owner.aa_worker.mobile, aa_case_id: aa_case.id)
    #sms =  Sms::Out.new(content: content, mobile:"18616015606", aa_case_id: aa_case.id)
    return sms
  end

  def customer_received(aa_case)
    content = OPTIONS["sms_template"]["customer_received"] % {:customer_name => aa_case.customer_name, :type => aa_case.rescue_type,
      :no => aa_case.no, :phone => aa_case.bind_customer_and_worker_did}
    sms =  Sms::Out.new(content: content, mobile:aa_case.customer_mobile, aa_case_id: aa_case.id)
    return sms
  end

  def customer_dispatched(aa_case)

    content = OPTIONS["sms_template"]["customer_dispatched"] % {:customer_name => aa_case.customer_name, :type => aa_case.rescue_type,
      :no => aa_case.no, :phone => aa_case.bind_customer_and_worker_did, :vendor_name => aa_case.aa_rescue.aa_vendor.name}
    sms =  Sms::Out.new(content: content, mobile:aa_case.customer_mobile, aa_case_id: aa_case.id)
    return sms
  end

  def customer_visited(aa_case)
    content = OPTIONS["sms_template"]["customer_visited"] % {:customer_name => aa_case.customer_name, :type => aa_case.rescue_type,
      :no => aa_case.no, :phone => aa_case.bind_customer_and_worker_did, :vendor_name => aa_case.aa_rescue.aa_vendor.name}
    sms =  Sms::Out.new(content: content, mobile:aa_case.customer_mobile, aa_case_id: aa_case.id)
    return sms
  end

  def vendor_dispathed(aa_case)
    content = OPTIONS["sms_template"]["vendor_dispathed"] % {:customer_name => aa_case.customer_name, :type => aa_case.rescue_type,
      :no => aa_case.no, :phone => '0108555', :address => aa_case.from_details,:car_vin =>aa_case.car_vin, :car_model => aa_case.car_model,
      :car_color => aa_case.car_color, :memo => aa_case.memo }
    sms =  Sms::Out.new(content: content, mobile:aa_case.aa_rescue.aa_vendor.telephone, aa_case_id: aa_case.id)
    return sms
  end

  def vendor_modify(aa_case)
    content = OPTIONS["sms_template"]["vendor_modify"] % {:customer_name => aa_case.customer_name, :type => aa_case.rescue_type,
      :no => aa_case.no, :phone => '0108555', :vendor_name => aa_case.aa_vendor.name}
    sms =  Sms::Out.new(content: content, mobile:aa_case.aa_rescue.aa_vendor.telephone, aa_case_id: aa_case.id)
    return sms
  end

  def vendor_finished(aa_case)
    content = OPTIONS["sms_template"]["vendor_finished"] % {:customer_name => aa_case.customer_name, :type => aa_case.rescue_type,
      :no => aa_case.no, :phone => '0108555', :vendor_name => aa_case.aa_vendor.name}
    sms =  Sms::Out.new(content: content, mobile:aa_case.aa_rescue.aa_vendor.telephone, aa_case_id: aa_case.id)
    return sms
  end
end