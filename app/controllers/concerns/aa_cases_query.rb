module AaCasesQuery
  extend ActiveSupport::Concern

  def get_aa_cases(aa_cases)
      all_cases = aa_cases.search(params[:search]).base_scope.
                  between_connected_at(params[:created_begin_at].to_s=='' ? params[:created_begin_at] : (params[:created_begin_at].to_datetime-8.hours).to_s, params[:created_end_at].to_s=='' ? params[:created_end_at] : (params[:created_end_at].to_datetime-8.hours).to_s).
                  #between_dispatched_at(params[:dispatched_begin_at], params[:dispatched_end_at]).
                  like_no(params[:no]).
                  equal_from_province(params[:from_province]).
                  like_customer_no(params[:customer_no]).
                  like_owner_no(params[:owner_no]).
                  like_car_license_no(params[:car_license_no]).
                  like_trailer_license_no(params[:trailer_license_no]).
                  like_dispatcher_no(params[:dispatcher_no]).
                  like_car_model(params[:car_model]).
                  like_from_details(params[:address]).
                  like_customer_mobile(params[:customer_mobile]).
                  like_customer_name(params[:customer_name]).
                  like_client_service_name(params[:client_service_name]).
                  like_data_source(params[:data_source]).
                  like_out_source_no(params[:out_source_no]).
                  search_vendor(params[:aa_vendor_name]).
                  search_dispatcher_flags(params[:dispatched_flag])

      unless params[:from_aa_case_id].nil?
        all_cases = all_cases.where("id <> ?", params[:from_aa_case_id])
      end

      if current_user.account_type == "供应商"
        all_cases = all_cases.search_by_current_user(current_user)  
      end

      return all_cases.includes(:aa_case_logs,:owner)
  end
end