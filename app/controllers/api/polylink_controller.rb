class Api::PolylinkController < ApplicationController
  protect_from_forgery except: :receive_customer

  TEMP_KEY = "8441d468ef1581d854bf1a851b3a818f"

  def create_cdr
    api_return = {}

    if verify_sign?
      cdr = get_cdr
      unless cdr.nil?
        result = verify(cdr)
        if result.length > 0
          api_return[:code] = "300"
          api_return[:message] = result.join(';')
        else
          api_return[:code] = "000"
          api_return[:message] = "成功"
        end
      else
        api_return[:code] = "200"
        api_return[:message] = "数据不是规范的JSON格式"
      end
    else
      api_return[:code] = "100"
      api_return[:message] = "sign无法通过验证"
    end

    render json: api_return
  end

  def verify(cdr)
    errors = []
    errors << "did不能为空" if cdr["did"].blank?
    errors << "bind_id不能为空" if cdr["bind_id"].blank?
    errors << "device_name不能为空" if cdr["device_name"].blank?
    errors << "from不能为空" if cdr["from"].blank?
    errors << "to不能为空" if cdr["to"].blank?
    errors << "started_at不能为空" if cdr["started_at"].blank?
    errors << "ended_at不能为空" if cdr["ended_at"].blank?
    errors << "duration不能为空" if cdr["duration"].blank?
    errors << "record_path录音文件" if cdr["record_path"].blank?
    errors << "call_status不能为空" if cdr["call_status"].blank?
    errors << "call_status值不符合规范" unless ["CONGESTION", "ANSWER", "BUSY", "CANCEL"].include?(cdr["call_status"])
    errors
  end

  def get_cdr
    cdr = nil
    begin
      request.body.rewind
      cdr = JSON.parse(request.body.read)
    rescue Exception => e
      Rails.logger.debug e
      Rails.logger.debug "转换CDR失败"
    end
    cdr
  end

  def verify_sign?
    # https://github.com/rails/rails/issues/11402
    request.body.rewind
    return false if params[:sign].blank? || params[:sign] != Digest::MD5.hexdigest("#{request.body.read}#{TEMP_KEY}")
    return true
  end
end