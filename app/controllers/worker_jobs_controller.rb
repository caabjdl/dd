class WorkerJobsController < ApplicationController
  load_and_authorize_resource
  # GET /worker_jobs
  # GET /worker_jobs.json
  def index
    @worker_jobs = WorkerJob.all.page(params[:page])
  end

  # GET /worker_jobs/1
  # GET /worker_jobs/1.json
  def show
  end

  # GET /worker_jobs/new
  def new
    @worker_job = WorkerJob.new
  end

  # GET /worker_jobs/1/edit
  def edit
  end

  # POST /worker_jobs
  # POST /worker_jobs.json
  def create
    @worker_job = WorkerJob.new(worker_job_params)

    respond_to do |format|
      if @worker_job.save
        format.html { redirect_to @worker_job, notice: 'Worker job was successfully created.' }
        format.json { render action: 'show', status: :created, location: @worker_job }
      else
        format.html { render action: 'new' }
        format.json { render json: @worker_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /worker_jobs/1
  # PATCH/PUT /worker_jobs/1.json
  def update
    respond_to do |format|
      if @worker_job.update(worker_job_params)
        format.html { redirect_to @worker_job, notice: 'Worker job was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @worker_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /worker_jobs/1
  # DELETE /worker_jobs/1.json
  def destroy
    @worker_job.destroy
    respond_to do |format|
      format.html { redirect_to worker_jobs_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_worker_job
      @worker_job = WorkerJob.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def worker_job_params
      params.require(:worker_job).permit(:owner_id, :customer_name, :customer_mobile, :car_license_no, :car_vin, :car_model, :car_color, :rescue_type, :rescue_reason, :from_province, :from_city, :from_region, :from_details, :to_province, :to_city, :to_region, :to_details, :aa_rescue_id)
    end
end
