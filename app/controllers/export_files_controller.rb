class ExportFilesController < ApplicationController
  load_and_authorize_resource

  def index
    @export_files = ExportFile.all.page(params[:page])
  end

  def new
    now1 = Time.now
    Export::ExportXls.create_aa_cases_zip
    now2 = Time.now
    redirect_to export_files_path
  end

  def download
    @export_file = ExportFile.find(params[:id])
    send_file @export_file.path
  end

  def subscribe
    current_user.subscribe_export = !current_user.subscribe_export
    current_user.save
    redirect_to export_files_path
  end
end
