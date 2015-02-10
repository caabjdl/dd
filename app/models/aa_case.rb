#encoding: utf-8
require 'erb'

class AaCase < ActiveRecord::Base
  include Sequenable
  include Assignable
  include Searchable
  include ExportCsv

  has :owner, :dispatcher, :creater
  sequence :CS
  quick_search :no, :customer_no, :customer_name, :customer_mobile, :car_license_no, :from_details, :out_source_no, :car_vin
  has_many :vsalad_medias
  has_many :aa_case_logs
  belongs_to :client
  belongs_to :customer
  belongs_to :customer_service


  has_many :pingan_api_operation_outs, :class_name => PinganApi::OperationOut
  has_many :pingan_api_operation_ins, :class_name => PinganApi::OperationIn
  has_many :pingan_api_salvation_outs, :class_name => PinganApi::SalvationOut
  has_many :pingan_api_salvation_ins, :class_name => PinganApi::SalvationIn
  has_many :pingan_api_salvation_query_ins, :class_name => PinganApi::SalvationQueryIn
  
  has_one :aa_rescue

  validates_presence_of :customer_account, if: Proc.new { |a| a.client_service_name == "中华联合" }
  validates_presence_of :car_license_no, :customer_name, :customer_mobile, :rescue_type, :rescue_reason, :from_details, if: Proc.new { |a| a.data_source != "平安接口" && a.data_source != "通用接口" }
  validates_presence_of :car_vin, if: Proc.new { |a| a.client_service_name == "东风本田" || a.client_service_name == "东风裕隆" }
  validates_presence_of :customer_no, if: Proc.new { |a| a.client_service_name == "广发银行"}
  validates_presence_of :out_source_no, :appointment_at, if: Proc.new { |a| a.client_service_name == "平安代驾"}
  validates_presence_of :out_source_no, if: Proc.new { |a| a.data_source == "平安接口" }
  validates_presence_of :client_service_name
  validate :validate_out_source_no_uniqueness
  validates_uniqueness_of :out_source_no, scope: :data_source, if: Proc.new { |a| a.data_source == "平安接口" }

  scope :unhandle, -> { where("aa_cases.owner_id is null").base_scope }
  scope :handle, -> { where("aa_cases.owner_id is not null").base_scope }
  scope :mine, ->(user) { where("aa_cases.owner_id = #{user.id}").base_scope }
  scope :accounting, -> { joins(:aa_rescue => :aa_vendor).where("aa_rescues.status in ('已完成','取消无空驶','取消有空驶') and aa_rescues.aa_vendor_id is not null and (aa_cases.is_accounted=0 or aa_cases.is_accounted is null ) and aa_vendors.name <> aa_rescues.aa_vendor_name").base_scope}
  scope :accounting_sure, -> { joins(:aa_rescue => :aa_vendor).where("aa_rescues.status in ('已完成','取消有空驶') and aa_rescues.aa_vendor_id is not null and (aa_cases.is_accounted=0 or aa_cases.is_accounted is null ) and aa_vendors.name = aa_rescues.aa_vendor_name").base_scope}
  scope :accounting_no_vendor, -> { joins(:aa_rescue).where("aa_rescues.aa_vendor_id is  null and (aa_cases.is_accounted=0 or aa_cases.is_accounted is null )").base_scope}
  scope :untreated, -> { joins(:aa_rescue).where("aa_cases.owner_id is not null and (aa_rescues.status = '' or aa_rescues.status is null) and TIMESTAMPDIFF(SECOND,CONVERT_TZ(aa_cases.created_at,'+00:00', '+08:00'), now() ) > 180").base_scope }
  scope :search_vendor, -> (aa_vendor_name) { joins(:aa_rescue=>:aa_vendor).where('aa_vendors.name like ? or aa_rescues.aa_vendor_name like ?',"%#{aa_vendor_name}%","%#{aa_vendor_name}%") unless aa_vendor_name.blank? }
  #scope :search_cancel_flag, -> (cancel_flag) { where("aa_rescues.canceled_at is %s NULL " % (cancel_flag=='true' ? 'not' : '')) unless cancel_flag.blank?}
  scope :search_dispatcher_flags, -> (dispatcher_flags) { joins(:aa_rescue).where('aa_rescues.status in (%s)' % dispatcher_flags.inspect[1...-1].gsub('"',"'")).base_scope if dispatcher_flags && !dispatcher_flags.blank?}
  # default_scope { where(!User.current_user.nil? ? "(#{table_name}.owner_aa_vendor_id = #{User.current_user.aa_vendor.id} or #{table_name}.creater_aa_vendor_id = #{User.current_user.aa_vendor.id})" : nil).filter_pingan.order("#{table_name}.id desc") }
  scope :base_scope, -> {where(!User.current_user.nil? ? "(#{table_name}.owner_aa_vendor_id = #{User.current_user.aa_vendor.id} or #{table_name}.creater_aa_vendor_id = #{User.current_user.aa_vendor.id})" : nil).filter_pingan.order("#{table_name}.id desc") }
  
  scope :export, -> { where("created_at between DATE_FORMAT(SUBDATE(NOW(),#{index+2}), '%y-%m-%d 16:00:00') and DATE_FORMAT(SUBDATE(NOW(),#{index+1}), '%y-%m-%d 16:00:00')").filter_pingan }
  scope :filter_pingan, -> {where("aa_cases.status <> '待平安系统确认'")}
  scope :filter_by_owner_and_status, -> (user){ joins(:aa_rescue).where("(aa_cases.owner_id = #{user.id})  and !(aa_rescues.status = \'已完成\' and :time_now > ADDDATE(aa_rescues.updated_at,interval 300 SECOND)) and  !(aa_rescues.status in (\'取消无空驶\',\'取消有空驶\') and :time_now > ADDDATE(aa_rescues.updated_at,interval 1500 SECOND)) ", :time_now => Time.now ).base_scope}
  scope :search_by_current_user, -> (user){ joins("inner join aa_vendors_accounts on aa_rescues.aa_vendor_id = aa_vendors_accounts.aa_vendor_id and aa_vendors_accounts.user_id = #{user.id}",:aa_rescue).base_scope}
  scope :pingan_cases, -> {where("aa_cases.data_source = '平安接口'")}
  paginates_per 10
  has_paper_trail
  before_create :assign_creater_no
  after_commit :auto_assign, on: :create
  after_create :notify_created, :update_address, :call_back

  def get_binding
    binding()
  end
  
  #TODO: 通话
  def bind_customer_and_worker_did
    did = ''
    # if self.aa_rescue && self.aa_rescue.worker_job && self.aa_rescue.worker_job.owner && self.aa_rescue.worker_job.owner.aa_worker
    #   did = Scallop.bind(self.customer_mobile, self.aa_rescue.worker_job.owner.aa_worker.mobile)
    # end
    p 'DID : '+ did
    return did
  end

  def assign_creater_no
    if !User.current_user
      user = nil
      if self.client_service_name.include?('平安')
        user = User.find_by_email(OPTIONS["pingan_api_account_email"])
      else
        user = User.find_by_email(OPTIONS["tongyong_api_account_email"])
      end
      self.assign_creater(user) if user
    else
      self.assign_creater(User.current_user)
    end
  end
  #准备调度
  def prepare_rescue(user)
    if self.aa_rescue.nil?
      self.aa_rescue = AaRescue.new.init(self, user)
      self.save
      WebsocketRails.users[user.id].send_message(:assigned, { no: self.no }, :namespace => :aa_cases) unless UserOnlineManager.connections_count_of(user) == 0
    end
    return self.aa_rescue
  end

  def call_back
    if self.customer
      CommonSalvationApiService.instance.salvation_callback(self)
    end
  end

  def self.batch_accounting(datas)
    return if datas.nil?
    datas.each do |data|
      aa_case = AaCase.base_scope.find(data[0])
      type = data[1][:type]
      amount = data[1][:fee]
      distance_arrive = data[1][:distance_arrive]
      distance_drag = data[1][:distance_drag]
      distance_empty_run = data[1][:distance_empty_run]
      distance_back = data[1][:distance_back]
      addition_fee = data[1][:addition_fee]
      caa_fee = data[1][:caa_fee]

      type_name =  type.blank? ? "非一口价" : "一口价"
      if aa_case.is_accounted.nil? || !aa_case.is_accounted
        accounting_job = AccountingJob.new
        accounting_job.aa_case = aa_case
        accounting_job.fee = amount.to_f if amount
        accounting_job.type = type_name
        accounting_job.apply_from = "dispatcher"
        accounting_job.distance_arrive = distance_arrive
        accounting_job.distance_drag = distance_drag
        accounting_job.distance_empty_run = distance_empty_run
        accounting_job.distance_back = distance_back
        accounting_job.addition_fee = addition_fee
        accounting_job.caa_fee = caa_fee

        accounting_job.save
      end
    end
  end

  def validate_out_source_no_uniqueness
    if self.data_source == "平安接口"
      file = File.open("tmp/locks/aa_cases_out_source_no.lock", "w")
      file.flock(File::LOCK_EX)
      
      errors.add(:out_source_no, "正在被其他操作占用") unless self.data_source == "平安接口" && UniqueNumberManager.lock!("aa_cases", "out_source_no", self.out_source_no, 1000)
      
      file.flock(File::LOCK_UN)
    end
  end

  def get_salvation_fee_type
     self.client_service_name ==  "平安非事故(自费)" ? "1" : "0"
  end

  def is_waiting_cancel
    return self.status == "等待取消"
  end

  def from_address
    address = "#{self.from_province},#{self.from_city},#{self.from_region},#{self.from_details}"
    return address.length>50 ? address[0,49] : address
  end

  def dep_code_convert
      code = OPTIONS["dep_code"][self.dep_code.to_i]
      return code.nil? ? self.dep_code : code 
  end
  # 看某人是否可以调度
  def can_assign_to?(user)
    if !self.owner.nil?
      Sidekiq.logger.info "任务 #{self.no} 已经有owner,用户 #{user.no} 不能调度 at #{Time.now}"
      return false
    end

    if !self.dispatcher.nil?
      Sidekiq.logger.info "任务 #{self.no} 已经有dispatcher,用户 #{user.no} 不能调度 at #{Time.now}"
      return false
    end

    if user.user_handle_client_services.where("name = :name", :name => self.client_service_name).exists?
      Sidekiq.logger.info "用户 #{user.no} 可以调度业务来源为 #{self.client_service_name} 的任务 at #{Time.now}"

      if user.user_handle_districts.where("province = :province and city = :city and region = :region", :province => self.from_province, :city => self.from_city, :region => self.from_region).exists?
        Sidekiq.logger.info "用户 #{user.no} 可以调度该区域 at #{Time.now}"
        return true
      end

      if user.user_handle_districts.where("province = :province and city = :city and (region is null or region = '')", :province => self.from_province, :city => self.from_city).exists?
        Sidekiq.logger.info "用户 #{user.no} 可以调度该市所有辖区 at #{Time.now}"
        return true
      end

      if user.user_handle_districts.where("province = :province and (city is null or city = '') and (region is null or region = '')", :province => self.from_province).exists?
        Sidekiq.logger.info "用户 #{user.no} 可以调度该省所有辖区 at #{Time.now}"
        return true
      end

      unless user.user_handle_districts.exists?
        Sidekiq.logger.info "任务 #{self.no} 区域信息被忽略,因为用户 #{user.no} 可以调度任何区域 at #{Time.now}"
        return true
      end

      Sidekiq.logger.info "用户 #{user.no} 不能调度该区域为 #{self.from_province} #{self.from_city} #{self.from_region} 的任务 at #{Time.now}"
      return false
    end

    Sidekiq.logger.info "用户 #{user.no} 不能调度业务来源为 #{self.client_service_name} 的任务 at #{Time.now}"
    return false
  end

  def init_data
    self.assign_creater(User.current_user)
    #self.created_at = Time.now
    self.connected_at = Time.now
  end

  def is_updated_by_date(cdate = Time.now- 1.days)
    created_at_date = Date.new(self.created_at.year,self.created_at.month,self.created_at.day)
    updated_at_date = Date.new(self.updated_at.year,self.updated_at.month,self.updated_at.day)
    date = Date.new(cdate.year,cdate.month,cdate.day)
    return created_at_date!= date && updated_at_date === date
  end
  
  def wait_cancel 
    self.status = "等待取消"
    if self.aa_rescue && !self.aa_rescue.status.blank? && self.aa_rescue.status.include?('取消')
      self.status = self.aa_rescue.status
    end
  end
  
  private
  # 自动分配
  def auto_assign
    AutoAssignManager.new_task(self)
  end

  def notify_created
    WebsocketRails[:aa_cases].trigger(:created, self)
  end

  def update_address
    GeoWorker.perform_async(self.id)
  end
end