# encoding: utf-8
require 'singleton'
class Services::SmsService
  include Singleton
  
  SERVER = SmsApi.config.server 
  SEND_URL   = "#{SERVER}/sms.aspx"
  STATUS_URL = "#{SERVER}/statusApi.aspx"
  CALL_URL = "#{SERVER}/callApi.aspx"

  USERID   = SmsApi.config.username
  ACCOUNT  = SmsApi.config.account
  PASSWORD = SmsApi.config.password

  def send_sms(sms)
    uri     = URI(SEND_URL)
    params  = {
                :action   => "send",
                :userid   => USERID,
                :account  => ACCOUNT,
                :password => PASSWORD,
                :mobile   => sms.mobile,
                :content  => sms.content,
                :sendTime => nil,
                :extno    => nil
              }
    request_at = Time.now
    uri.query = URI.encode_www_form(params)
    res       = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPSuccess)
      hash = Hash.from_xml(res.body)
      sms.task_id = hash["returnsms"]["taskID"]
    end
    sms.save

    log_save(request_at,params,res.body,res.code)
    return res.is_a?(Net::HTTPSuccess)
  end

  def status
    uri     = URI(STATUS_URL)
    params  = {
                :action   => "query",
                :userid   => USERID,
                :account  => ACCOUNT,
                :password => PASSWORD,
              }
    request_at = Time.now
    uri.query = URI.encode_www_form(params)
    res       = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPSuccess)
      hash = Hash.from_xml(res.body)
      
      ary = []
      obj = hash["returnsms"]["statusbox"]
      if obj.kind_of?(Array)
        ary = ary + obj
      else
        ary << obj if obj
      end

      ary.each do |status_box|
        sms_out = Sms::Out.find_by_task_id(status_box["taskid"])
        if sms_out && status_box["status"] == "10"
          sms_out.successed = true
          sms_out.successed_at = status_box["receivetime"].to_datetime
          sms_out.save
        end
      end
    end
    
    log_save(request_at,params,res.body,res.code)
    return res.is_a?(Net::HTTPSuccess)
  end

  def receive
    uri     = URI(CALL_URL)
    params  = {
                :action   => "query",
                :userid   => USERID,
                :account  => ACCOUNT,
                :password => PASSWORD,
              }
    uri.query = URI.encode_www_form(params)
    res       = Net::HTTP.get_response(uri)

    if res.is_a?(Net::HTTPSuccess)
      hash = Hash.from_xml(res.body)

      ary = []
      obj = hash["returnsms"]["callbox"]
      if obj.kind_of?(Array)
        ary = ary + obj
      else
        ary << obj if obj
      end
      ary.each do |call_box|
        sms_out = Sms::Out.find_by_task_id(call_box["taskid"])
        sms_in = Sms::In.new(mobile: call_box["mobile"],content:call_box["content"],task_id:call_box["taskid"],received_at: call_box["receivetime"].to_datetime)
        sms_in.aa_case_id = sms_out.aa_case_id if sms_out
        sms_in.save
      end
      
    end
    
    log_save(request_at,params,res.body,res.code)
    return res.is_a?(Net::HTTPSuccess)
  end

  def log_save(request_at,params,res_body,res_code)
    log = Sms::SmsLog.new( request_at: request_at,
                                        request_body: params.to_json,
                                        response_body: res_body ,
                                        response_at: Time.now,
                                        response_status:res_code)
    log.save
  end
end