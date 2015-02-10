class SmsApiStatusWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 1
  
  def perform(method)
    Services::SmsService.instance.send(method)
  end
end