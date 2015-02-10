# encoding: utf-8
class Api::VsaladController < ApplicationController
  protect_from_forgery except: :query

  def query
    desc = ''
    unless params[:open_id].blank?
      aa_case = AaCase.where("status not in ('已完成','取消无空驶','取消有空驶') and customer_open_id = ?",params[:open_id]).last
      
      if aa_case
        status = aa_case.aa_rescue.nil? ? aa_case.status : aa_case.aa_rescue.status 
        desc = "您的当前任务单号为:\x0A#{aa_case.no} \x0A目前状态为:\x0A#{status}\x0A"
      end
    end
    api_return = {}
    api_return[:return_code] = "999"
    api_return[:description] = desc
    render json: api_return
  end

  def receive
    unless params[:open_id].blank?
      aa_case = AaCase.where("status not in ('已完成','取消无空驶','取消有空驶') and customer_open_id = ?",params[:open_id]).last
      if aa_case
        vsalad_media = VsaladMedia.where(open_id:params[:open_id]).first
        if vsalad_media.nil?
          vsalad_media = VsaladMedia.new
        end
        vsalad_media.open_id = params[:open_id]
        vsalad_media.url = params[:url]
        vsalad_media.file_type = params[:file_type]
        vsalad_media.aa_case_id = aa_case.id
        vsalad_media.save
      end
    end
    api_return = {}
    api_return[:return_code] = "999"
    api_return[:description] = ''
    render json: api_return
  end
end