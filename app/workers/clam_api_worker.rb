class ClamApiWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 1
  
  def perform(aa_rescue_id)
    # sleep 5
    aa_rescue = AaRescue.find_by_id(aa_rescue_id)
    if aa_rescue.worker_jobs.enabled.first
      content = OPTIONS["clam_template"] % {
        no: aa_rescue.aa_case.no,
        customer_name: aa_rescue.aa_case.customer_name,
        customer_mobile: aa_rescue.aa_case.customer_mobile,
        car_license_no: aa_rescue.aa_case.car_license_no,
        car_model: aa_rescue.aa_case.car_model,
        from_details: aa_rescue.aa_case.from_details.blank? ? aa_rescue.aa_case.from_coordinate_address : aa_rescue.aa_case.from_details,
        type: aa_rescue.aa_case.rescue_type,
        memo: aa_rescue.aa_case.memo
      }
      Sidekiq.logger.info content
      Wechat::WechatService.instance.send_text("#{Rails.application.config.clam_api_host}/api/wx_adapters/send_text",aa_rescue.worker_jobs.enabled.first.owner.open_id,content)
    end
  end
end