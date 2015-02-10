class AutoAssignWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 0

  def perform
    AutoAssignManager.dispatch
  end

end