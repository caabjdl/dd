# encoding: utf-8
class UserOnlineManager

  $redis.keys("users:*:client_counter").each do |key|
    $redis.set key, 0
  end

  $redis.del("users:ready")
  $redis.del("users:away")
  $redis.del("users:busy")

  def self.ready_users
    User.where("users.id in (:ids)", :ids => $redis.lrange("users:ready", 0, -1))
  end

  def self.away_users
    User.where("users.id in (:ids)", :ids => $redis.lrange("users:away", 0, -1))
  end

  def self.busy_users
    User.where("users.id in (:ids)", :ids => $redis.lrange("users:busy", 0, -1))
  end

  def self.online_users
    User.where("users.id in (:ids)", :ids => $redis.lrange("users:away", 0, -1) + $redis.lrange("users:busy", 0, -1) + $redis.lrange("users:ready", 0, -1))
  end

  def self.set_ready(user)
    unless self.status_of(user) == "在线"
      Sidekiq.logger.info "用户 #{user.no} 设置状态:在线 at #{Time.now}"
      $redis.rpush "users:ready", user.id
      $redis.lrem "users:away", 0, user.id
      $redis.lrem "users:busy", 0, user.id
      $redis.set "users:#{user.id}:online_status", "在线"
      AutoAssignManager.log_on(user)
      WebsocketRails.users[user.id].send_message(:status_changed, { status: self.status_of(user) }, :namespace => :users) unless self.connections_count_of(user) == 0
    end
  end

  def self.heart_beat(user)
    WebsocketRails.users[user.id].send_message(:heart_beat_finished, { message: 'success' }, :namespace => :users)
  end

  def self.set_away(user)
    unless self.status_of(user) == "离开"
      Sidekiq.logger.info "用户 #{user.no} 设置状态:离开 at #{Time.now}"
      $redis.rpush "users:away", user.id
      $redis.lrem "users:busy", 0, user.id
      $redis.lrem "users:ready", 0, user.id
      $redis.set "users:#{user.id}:online_status", "离开"
      AutoAssignManager.log_off(user)
      WebsocketRails.users[user.id].send_message(:status_changed, { status: self.status_of(user) }, :namespace => :users) unless self.connections_count_of(user) == 0
    end
  end

  def self.set_busy(user)
    unless self.status_of(user) == "繁忙"
      Sidekiq.logger.info "用户 #{user.no} 设置状态:繁忙 at #{Time.now}"
      $redis.rpush "users:busy", user.id
      $redis.lrem "users:away", 0, user.id
      $redis.lrem "users:ready", 0, user.id
      $redis.set "users:#{user.id}:online_status", "繁忙"
      AutoAssignManager.log_off(user)
      WebsocketRails.users[user.id].send_message(:status_changed, { status: self.status_of(user) }, :namespace => :users) unless self.connections_count_of(user) == 0
    end
  end

  def self.set_offline(user)
    unless self.status_of(user) == "离线"
      Sidekiq.logger.info "用户 #{user.no} 设置状态:离线 at #{Time.now}"
      $redis.lrem "users:busy", 0, user.id
      $redis.lrem "users:ready", 0, user.id
      $redis.lrem "users:away", 0, user.id
      $redis.set "users:#{user.id}:online_status_before_offline", self.status_of(user)
      $redis.set "users:#{user.id}:online_status", "离线"
      AutoAssignManager.log_off(user)
      WebsocketRails.users[user.id].send_message(:status_changed, { status: self.status_of(user) }, :namespace => :users) unless self.connections_count_of(user) == 0
    end
  end

  def self.connected(user)
    $redis.setnx "users:#{user.id}:client_counter", 0
    $redis.set("users:#{user.id}:client_counter", 0) if self.connections_count_of(user) < 0
    $redis.incr "users:#{user.id}:client_counter"
    if self.status_of(user) == "离线"
      self.set_status(user, $redis.get("users:#{user.id}:online_status_before_offline"))
    else
      self.set_status(user, self.status_of(user))
    end
  end

  def self.disconnected(user)
    $redis.setnx "users:#{user.id}:client_counter", 1
    $redis.set("users:#{user.id}:client_counter", 1) if self.connections_count_of(user) < 1
    $redis.decr "users:#{user.id}:client_counter"
    if self.connections_count_of(user) == 0
      UserOnlineStatusWorker.perform_in(15.seconds, "away", user.id)
      UserOnlineStatusWorker.perform_in(5.minutes, "offline", user.id)
    end
  end

  def self.set_status(user, status)
    case status
    when "在线"
      self.set_ready(user)
    when "离开"
      self.set_away(user)
    when "繁忙"
      self.set_busy(user)
    when "离线"
      self.set_offline(user)
    else
      self.set_busy(user)
    end
  end

  def self.status_of(user)
    $redis.get "users:#{user.id}:online_status"
  end

  def self.adjust_connections_count
    # WebsocketRails.users.each do |user|

    # end
  end

  def self.connections_count_of(user)
    #Sidekiq.logger.info WebsocketRails.users.methods
    #WebsocketRails.users[user.id].connections.length if WebsocketRails.users[user.id].is_a?(WebsocketRails::UserManager::LocalConnection)
    #return WebsocketRails.users[user.id].connections.length if WebsocketRails.users[user.id].is_a?(WebsocketRails::UserManager::LocalConnection)
    $redis.get("users:#{user.id}:client_counter").to_i# if WebsocketRails.users[user.id].is_a?(WebsocketRails::UserManager::MissingConnection)
    #return 9999
    #$redis.get("users:#{user.id}:client_counter").to_i
  end
end