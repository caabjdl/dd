class VsaladApiWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 3
  
  def perform(worker_job_id)
    worker_job = WorkerJob.find_by_id(worker_job_id)
    mobile = ''
    if worker_job && worker_job.aa_rescue  && worker_job.owner && worker_job.owner.aa_worker
      mobile = worker_job.owner.aa_worker.mobile
    end
    if worker_job && worker_job.aa_case.customer_open_id
      content = OPTIONS["vsalad_template"] % {
        name: worker_job.owner.name,
        status: worker_job.status,
        phone: mobile
      }
      Wechat::WechatService.instance.send_text("#{Rails.application.config.vsalad_api_host}/api/wx_adapters/send_text",worker_job.aa_case.customer_open_id,content)
    end
  end
end