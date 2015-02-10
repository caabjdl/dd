class AccountingJobsController < ApplicationController
  load_resource :except => [:fast_create]
  authorize_resource

  def index
    @accounting_jobs = self.get_accountings(@accounting_jobs).completed.page(params[:page])                    
  end

  def show
  end

  def fast_create
    aa_rescue_id = params[:id]
    AccountingJob.create_by_rescue(params[:id].to_i,params[:fee].to_f)
      
    redirect_to request.referer
  end

  def export
    @accounting_jobs = @accounting_jobs.completed.search(params[:search]).
                    between_completed_at(params[:completed_begin_at].to_s=='' ? params[:completed_begin_at] : (params[:completed_begin_at].to_datetime-8.hours).to_s, params[:completed_end_at].to_s=='' ? params[:completed_end_at] : (params[:completed_end_at].to_datetime-8.hours).to_s).
                    search_vendor(params[:aa_vendor_name])  
    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    export_xls = Export::ExportXls.new(@accounting_jobs,"#{Rails.root}/app/views/accounting_jobs/export.xls.erb")
    send_data export_xls.gzip(timestamp + "_accounting_jobs.xls"),:type => 'application/zip',:filename => timestamp + '_accounting_jobs.zip'
  end

  def agree
    @accounting_job.agree
    @accounting_job.save
    redirect_to request.referer
  end

  def batch_agree
    AccountingJob.batch_agree(params[:ids])
    redirect_to request.referer
  end

  def unagree
    @accounting_job.update_attributes(params.require(:accountings).require("#{params[:id]}").permit!)
    @accounting_job.save
    redirect_to request.referer
  end

  def verify_by_finance
    @accounting_jobs = self.get_accountings(@accounting_jobs).verify_by_finance.page(params[:page])
  end

  def verify_by_vendor
    @accounting_jobs = self.get_accountings(@accounting_jobs).verify_by_vendor.page(params[:page])
  end

  def new
    aa_rescue_id = params[:aa_rescue_id]
    @accounting_job_by_id = AccountingJob.where("aa_rescue_id = ?",aa_rescue_id).first
    if @accounting_job_by_id.nil?
      @accounting_job.aa_rescue_id = params[:aa_rescue_id]
      @accounting_job.aa_rescue = AaRescue.find(params[:aa_rescue_id])
      @accounting_job.aa_case = AaRescue.find(params[:aa_rescue_id]).aa_case
    else
      redirect_to edit_accounting_job_path(@accounting_job_by_id)
    end
    
  end

  def edit
  end

  def create
    @accounting_job = AccountingJob.new(accounting_job_params)

    if @accounting_job.save
      redirect_to edit_accounting_job_path(@accounting_job)
    else
      render action: 'new'
    end
  end

  def update
    if @accounting_job.update(accounting_job_params)
      redirect_to edit_accounting_job_path(@accounting_job)
    else
      render action: 'edit'
    end
  end


  def get_accountings(accounting_jobs)
      q_accounting_jobs = accounting_jobs.search(params[:search]).
                    between_completed_at(params[:completed_begin_at].to_s=='' ? params[:completed_begin_at] : (params[:completed_begin_at].to_datetime-8.hours).to_s, params[:completed_end_at].to_s=='' ? params[:completed_end_at] : (params[:completed_end_at].to_datetime-8.hours).to_s).
                    equal_type(params[:type]).search_vendor(params[:aa_vendor_name]).search_client_service_name(params[:client_service_name]).
                    search_min_distance(params[:min_distance]).search_max_distance(params[:max_distance]).search_rescue_type(params[:rescue_type]).
                    search_case_begin(params[:case_begin_at].to_s=='' ? params[:case_begin_at] : (params[:case_begin_at].to_datetime-8.hours).to_s).
                    search_case_end(params[:case_end_at].to_s=='' ? params[:case_end_at] : (params[:case_end_at].to_datetime-8.hours).to_s).
                    search_rescue_status(params[:status])
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def accounting_job_params
      params.require(:accounting_job).permit(:confirm_fee, :aa_case_id, :aa_rescue_id,:confirm_distance_arrive,
        :confirm_distance_drag,:confirm_distance_back,:confirm_distance_empty_run,:confirm_caa_fee,:confirm_other_fee,
        :confirm_addition_fee,:accounting_job_logs_attributes => [:content])
    end

    
end
