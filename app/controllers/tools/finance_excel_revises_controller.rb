class Tools::FinanceExcelRevisesController < ApplicationController
  authorize_resource :class => false
  protect_from_forgery :except => :import

  def index
    
  end

  def import
    # e = ExportFile.new
    # e.path = File.open("start.sh")
    # e.save
    # redirect_to "index"
    send_file Export::ImportXls.import(params[:file])
  end
end
