class PinganPhotosController < ApplicationController
  load_and_authorize_resource

  def new
    @pingan_photo.aa_case_id = params[:aa_case_id]
    @aa_rescue = AaCase.find_by_id(params[:aa_case_id]).aa_rescue
    worker_jobs = @aa_rescue.worker_jobs
    # @wechat_medias = worker_job.wechat_medias if worker_job
  end

  def create
    @pingan_photo = PinganPhoto.new(pingan_photo_params)
    @pingan_photo.set_data(params[:media_file],params[:attachment_file])
    @pingan_photo.save
    redirect_to pingan_photos_path, notice: '创建成功.'
  end

  def index
    @pingan_photos = @pingan_photos.page(params[:page])
  end

  def edit
    
  end

  def update

  end

  private
  def pingan_photo_params
    params.require(:pingan_photo).permit(
      :photo1_url,:photo1_name,:photo1_gps_x,:photo1_gps_y,:photo1_created_at,
      :photo2_url,:photo2_name,:photo2_gps_x,:photo2_gps_y,:photo2_created_at,
      :photo3_url,:photo3_name,:photo3_gps_x,:photo3_gps_y,:photo3_created_at,
      :photo4_url,:photo4_name,:photo4_gps_x,:photo4_gps_y,:photo4_created_at,
      :photo5_url,:photo5_name,:photo5_gps_x,:photo5_gps_y,:photo5_created_at,
      :aa_rescue_id,:aa_case_id,:user_id,:aa_case_no)
  end
end