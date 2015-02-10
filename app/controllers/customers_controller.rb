# encoding: utf-8
class CustomersController < ApplicationController
  load_and_authorize_resource

  def index
    @customers = @customers.search(params[:search]).page(params[:page])
    p @customers
  end

  def show
  end

  def export
    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    export_xls = Export::ExportXls.new(@customers.search(params[:search]),"#{Rails.root}/app/views/customers/export.xls.erb")
    send_data export_xls.gzip(timestamp + "_customers.xls"),:type => 'application/zip',:filename => timestamp + '_customers.zip'
  end
end
