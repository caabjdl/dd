class CommonApiWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 0

  def perform(aa_case_id)
    CommonSalvationApiService.instance.salvation_callback_execute(aa_case_id)
  end

end