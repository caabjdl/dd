class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :set_current_user
  before_filter :configure_permitted_parameters, if: :devise_controller?
  after_filter :store_location
  layout :layout_by_resource

  before_filter do
    resource = controller_name.singularize.to_sym
    action = action_name.singularize.to_sym
    method_each_action = "#{action}_#{resource}_params"
    method_all_in_one = "#{resource}_params"
    params[resource] &&= (send(method_each_action) if respond_to?(method_each_action, true)) || (send(method_all_in_one) if respond_to?(method_all_in_one, true))
  end

  rescue_from CanCan::AccessDenied do |exception|
    #sign_out current_user
    #redirect_to new_user_session_url, :alert => exception.message
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"
    redirect_to root_path
  end

  # paper_trail
  def user_for_paper_trail
    current_user  if user_signed_in?
  end
  
  # def default_url_options
  #   if Rails.env.production?
  #     { :host => "ddtest.caa.com.cn" }
  #   end
  # end

  def layout_by_resource
    if devise_controller?
      'devise'
    else
      case action_name 
      when 'index' then 'list'
      when 'show','new','edit','update','create'  then 'form'
      else 'application' end if controller_name!='home'
    end
  end

  def after_sign_in_path_for(resource)
    dash_board(resource)
  end

  def after_sign_out_path_for(resource)
    new_user_session_url
  end

  def set_current_user
    User.current_user = current_user
  end

  def user_for_paper_trail
    current_user if user_signed_in?
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:no, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :no, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:no, :email, :password, :password_confirmation, :current_password) }
  end

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    if (request.fullpath != "/users/sign_in" &&
        request.fullpath != "/users/sign_up" &&
        request.fullpath != "/users/sign_out" &&
        request.fullpath != "/users/password" &&
        request.fullpath != "/" &&
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath 
    end
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  private

  def dash_board(user)
    case user.role
    when "调度组长"
      aa_cases_url
    when "供应商管理"
      aa_vendors_url
    when "调度"
      mine_aa_cases_path
    else 
      root_path
    end
  end
end

