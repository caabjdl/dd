class AccountingJob < ActiveRecord::Base
  include Searchable

  self.inheritance_column = nil
  belongs_to :aa_rescue
  belongs_to :aa_case
  belongs_to :aa_vendor
  has_many :accounting_job_logs
  before_save :log, :set_association,:set_status
  accepts_nested_attributes_for :accounting_job_logs
  scope :search, ->(search_string) { joins(:aa_vendor).where("aa_vendors.name like :search_string or accounting_jobs.status like :search_string",:search_string =>"%#{search_string}%") unless search_string.blank? }
  scope :search_vendor, -> (aa_vendor_name) { joins(:aa_vendor).where('aa_vendors.name like ?',"%#{aa_vendor_name}%") unless aa_vendor_name.blank? }
  scope :search_case_begin, -> (begin_at) { joins(:aa_case).where("aa_cases.created_at > ?",begin_at) unless begin_at.blank? }
  scope :search_case_end, -> (end_at) { joins(:aa_case).where("aa_cases.created_at < ?",end_at) unless end_at.blank? }
  scope :search_rescue_status, -> (status) { joins(:aa_rescue).where("aa_rescues.status = ?",status) unless status.blank? }
  scope :search_min_distance, ->(min_distance) { joins(:aa_rescue).where("(ifnull(aa_rescues.distance_arrive,0) + ifnull(aa_rescues.distance_drag,0) +ifnull(aa_rescues.distance_back,0)) > ?",min_distance.to_i) unless min_distance.blank? }
  scope :search_max_distance, ->(max_distance) { joins(:aa_rescue).where("(ifnull(aa_rescues.distance_arrive,0) + ifnull(aa_rescues.distance_drag,0) +ifnull(aa_rescues.distance_back,0)) < ?",max_distance.to_i) unless max_distance.blank? }
  scope :search_client_service_name, ->(client_service_name) {joins(:aa_case).where("aa_cases.client_service_name = ?",client_service_name) unless client_service_name.blank? }
  scope :search_rescue_type, ->(types) {joins(:aa_case).where("aa_cases.rescue_type in (?)",types ) unless types.nil?}
  scope :verify_by_finance, -> {where("accounting_jobs.status='待结算部核算'")}
  scope :verify_by_vendor, -> { where("accounting_jobs.status='待供应商核算'")}
  scope :completed, -> {where("accounting_jobs.status='已完成'")}
  default_scope { order("#{table_name}.id desc") }
  def log
    self.accounting_job_logs.each do |log| 
      if log.new_record?
        log.user = User.current_user
      end
    end
  end

  def set_association
    if self.aa_rescue_id
      self.aa_case_id =  self.aa_rescue.aa_case.id 
      self.aa_vendor_id = self.aa_rescue.aa_vendor.id if self.aa_rescue.aa_vendor
    elsif self.aa_case_id
      self.aa_rescue_id =  self.aa_case.aa_rescue.id
      self.aa_vendor_id = self.aa_case.aa_rescue.aa_vendor.id if self.aa_case.aa_rescue.aa_vendor
    end
    if self.aa_case
      self.aa_case.is_accounted = true
      self.aa_case.save
    end
  end

  def agree
    self.confirm_fee = self.fee
    self.confirm_distance_back = self.distance_back
    self.confirm_distance_arrive = self.distance_arrive
    self.confirm_distance_drag = self.distance_drag
    self.confirm_distance_empty_run = self.distance_empty_run
    self.confirm_caa_fee = self.caa_fee
    self.confirm_addition_fee = self.addition_fee
    self.confirm_other_fee = self.other_fee
  end

  def self.batch_agree(ids)
    accounting_jobs =  AccountingJob.find(ids.split(","))
    accounting_jobs.each do |ac|
      ac.agree
      ac.save
    end
  end

  def set_status
    if self.fee == self.confirm_fee
      self.status = "已完成"
      self.completed_at = Time.now
    else
      self.status = "待供应商核算"
    end
  end

  def self.create_by_rescue(aa_rescue_id,fee)
    accounting_job = AccountingJob.new
    accounting_job_by_id = AccountingJob.where("aa_rescue_id = ?",aa_rescue_id).first

    unless accounting_job_by_id.nil?
      accounting_job = accounting_job_by_id
    end
    aa_rescue = AaRescue.find(aa_rescue_id)
    accounting_job.aa_rescue_id = aa_rescue_id
    accounting_job.aa_rescue = aa_rescue
    accounting_job.aa_case = aa_rescue.aa_case
    accounting_job.fee = fee
    accounting_job.distance_arrive = aa_rescue.distance_arrive
    accounting_job.distance_drag = aa_rescue.distance_drag
    accounting_job.distance_empty_run = aa_rescue.distance_empty_run
    accounting_job.distance_back = aa_rescue.distance_back
    accounting_job.caa_fee = aa_rescue.fee
    accounting_job.addition_fee = aa_rescue.addition_fee
    accounting_job.other_fee = aa_rescue.other_fee
    accounting_job.save
  end
end
