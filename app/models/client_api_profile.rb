# encoding: utf-8
class ClientApiProfile < ActiveRecord::Base
  include Searchable
  include Disable

  # association
  belongs_to :client

  # validate
  validates_presence_of :cid, :secret, :client_service_name
  validates_uniqueness_of :cid, :secret, :client_service_name

  # callback
  after_initialize :generate_secret

  paginates_per 10
  quick_search :cid, :secret, :client_service_name

  def generate_secret
    self.secret ||= SecureRandom.hex
  end
end