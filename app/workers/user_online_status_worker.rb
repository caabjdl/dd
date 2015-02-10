class UserOnlineStatusWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 0

  def perform(status, user_id)
    user = User.find_by_id(user_id) unless user_id.nil?
    unless user.nil?
      Sidekiq.logger.info "用户 #{user.no} 连接数为 #{UserOnlineManager.connections_count_of(user)} at #{Time.now}"
      case status
      when "offline"
        if UserOnlineManager.connections_count_of(user) == 0
          Sidekiq.logger.info "用户 #{user.no} 离线 at #{Time.now}"
          UserOnlineManager.set_offline(user)
        end
      when "away"
        if UserOnlineManager.connections_count_of(user) == 0
          Sidekiq.logger.info "用户 #{user.no} 离开 at #{Time.now}"
          UserOnlineManager.set_away(user)
        end
      else
      end
    end
  end
end