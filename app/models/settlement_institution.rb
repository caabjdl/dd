# encoding: utf-8
class SettlementInstitution < ActiveRecord::Base
  include Searchable
  belongs_to :client_service
end