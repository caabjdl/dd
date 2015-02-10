# encoding: utf-8
class Api::ClamController < ApplicationController
  protect_from_forgery except: :receive

  def receive
    p params

    worker_job = WorkerJob.find_by_id(params[:worker_job_id])
    if worker_job
      #反馈用户
      VsaladApiWorker.perform_async(params[:worker_job_id])
      #回传状态
      worker_job.call_status_back_to_rescue
    end
    api_return = {}
    api_return[:return_code] = "999"
    api_return[:description] = ''
    
    render json: api_return
  end

end