# encoding: utf-8
require 'mongoid'
class Sms::SmsLog
  include Mongoid::Document
  field :request_at, type: DateTime
  field :request_body, type: String

  field :response_at, type: DateTime
  field :response_body, type: String
  field :response_status, type: String
end