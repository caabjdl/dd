# encoding: utf-8
class AutoAssignManager

  $redis.setnx("auto_assign:stats:running", false)
  $redis.del("users:assign")
  $redis.del("users:assign_direct")
  $redis.del("tasks:unhandle")
  $redis.setnx("auto_assign:stats:counter", 0)
  $redis.set("auto_assign:stats:dispatching", false)

  def self.new_task(aa_case)
    Sidekiq.logger.info "接收到新任务#{aa_case.no} at #{Time.now}"
    AutoAssignWorker.perform_async
  end

  def self.tasks
    AaCase.unscoped.where("id in (:ids)", :ids => $redis.lrange("tasks:unhandle", 0, - 1))
  end

  def self.users
    User.where("id in (:ids) or id in (:direct_ids)", :ids => $redis.lrange("users:assign", 0, - 1), :direct_ids => $redis.lrange("users:assign_direct", 0, - 1))
  end

  def self.last_assigned_of(user)
    return $redis.get("users:#{user.id}:last_assigned_at").to_datetime unless $redis.get("users:#{user.id}:last_assigned_at").nil?
    return nil
  end

  def self.log_off(user)
    $redis.lrem "users:assign", 0, user.id
    $redis.lrem "users:assign_direct", 0, user.id
    Sidekiq.logger.info "用户 #{user.no} 离开队列 at #{Time.now}"
  end

  def self.log_on(user)
    ActiveRecord::Base.uncached do
      user.reload
    end
    Sidekiq.logger.info "用户 #{user.no} 自动分配状态 #{user.can_auto_assign_to} at #{Time.now}"
    if user.can_auto_assign_to
      if user.account_type == "直派供应商"
        $redis.rpush "users:assign_direct", user.id
        Sidekiq.logger.info "用户 #{user.no} 进入优先队列 at #{Time.now}"
        AutoAssignWorker.perform_async
      else
        $redis.rpush "users:assign", user.id
        Sidekiq.logger.info "用户 #{user.no} 进入普通队列 at #{Time.now}"
        AutoAssignWorker.perform_async
      end
    end
    
  end

  def self.count_of_users
    $redis.llen("users:assign").to_i + $redis.llen("users:assign_direct").to_i
  end

  def self.load_all_tasks
    $redis.del("tasks:unhandle")
    AaCase.unscoped.where("owner_id is null and status = ''").each do |item|
      $redis.rpush "tasks:unhandle", item.id
    end
  end

  def self.assign(task, redis_key)

    assign_flag = false
    Sidekiq.logger.info "当前队列有 #{$redis.llen(redis_key).to_i} 个人 at #{Time.now}"

    unless $redis.llen(redis_key).to_i == 0
      if self.auto_assignable?(task)
        $redis.del "users:assign_this_loop"
        $redis.rpush("users:assign_this_loop", $redis.lrange(redis_key, 0, -1)) unless $redis.llen(redis_key).to_i == 0

        while $redis.llen("users:assign_this_loop").to_i > 0 do
          user_id = $redis.lpop "users:assign_this_loop"
          user = User.find_by_id(user_id) unless user_id.nil?

          unless user.nil?
            ActiveRecord::Base.uncached do
              user.reload
            end
            Sidekiq.logger.info "取出用户 #{user.no} at #{Time.now}"

            if can_assign_to_at_this_time?(user) && user.can_auto_assign_to && task.can_assign_to?(user)
              task.prepare_rescue(user)
              task.aa_rescue.assign_worker(user) if task.aa_rescue
              time = Time.now
              $redis.set "users:#{user.id}:last_assigned_at", time
              $redis.incr "auto_assign:stats:counter"
              $redis.hsetnx "users:#{user.id}:assign_history", task.id, time
              $redis.hsetnx "auto_assign:logs:assign_history", task.id, user.id
              $redis.rpush "tasks:assign_this_loop", task.id
              $redis.lrem redis_key, 0, user.id
              $redis.rpush redis_key, user.id
              assign_flag = true
              Sidekiq.logger.info "任务 #{task.no} 已经分配给 #{user.no} at #{Time.now}"
            else
              $redis.lrem redis_key, 0, user.id
              $redis.lpush redis_key, user.id
            end
          end
        end
        
        Sidekiq.logger.info "任务 #{task.no} 未分配 at #{Time.now}"
      else
        Sidekiq.logger.info "任务 #{task.no} 不能自动分配,移出队列 at #{Time.now}"
      end
    end

    Sidekiq.logger.info "当前队列分配结束 at #{Time.now}"

    return assign_flag
  end

  def self.dispatch
    if self.running?
      file = File.open("tmp/locks/auto_assign.lock", "w")
      file.flock(File::LOCK_EX)

      Sidekiq.logger.info "开始分配任务 at #{Time.now}"
      self.start_dispatch

      Sidekiq.logger.info "当前可分配的用户在线人数 #{self.count_of_users} at #{Time.now}"

      unless self.count_of_users == 0
        self.load_all_tasks

        Sidekiq.logger.info "当前队列有 #{$redis.llen('tasks:unhandle')} 个任务 at #{Time.now}"

        while $redis.llen("tasks:unhandle").to_i > 0 do
          Sidekiq.logger.info "任务剩余 #{$redis.llen('tasks:unhandle')} at #{Time.now}"
          task_id = $redis.lpop "tasks:unhandle"
          task = AaCase.find_by_id(task_id) unless task_id.nil?

          unless task.nil?
            ActiveRecord::Base.uncached do
              task.reload
            end
            Sidekiq.logger.info "取出任务 #{task.no} at #{Time.now}"
            
            # 如果直排没分配出去,就分到普通的队列
            Sidekiq.logger.info "启动优先分配队列 at #{Time.now}"
            unless self.assign(task, "users:assign_direct")
              Sidekiq.logger.info "进入普通分配队列 at #{Time.now}"
              self.assign(task, "users:assign")
            end
          end
        end
      end

      #AutoAssignWorker.perform_in(1.minutes)
      #Sidekiq.logger.info "本次分配结束,剩余 #{$redis.llen('tasks:unhandle')} 个任务,下次分配在 1 分钟之后重新开始 at #{Time.now}"
      Sidekiq.logger.info "本次分配结束,剩余 #{$redis.llen('tasks:unhandle')} 个任务 at #{Time.now}"
      
      self.stop_dispatch
      file.flock(File::LOCK_UN)
    else
      Sidekiq.logger.info "当前自动分配任务已经关闭 at #{Time.now}"
    end
  end

  def self.running?
    $redis.get("auto_assign:stats:running") == "true"
  end

  def self.dispatching?
    $redis.get("auto_assign:stats:dispatching") == "true"
  end

  def self.start_dispatch
    $redis.set "auto_assign:stats:dispatching", true
    $redis.set "auto_assign:stats:dispatch_start_at", Time.now
  end

  def self.stop_dispatch
    $redis.set "auto_assign:stats:dispatching", false
    $redis.set "auto_assign:stats:dispatch_stop_at", Time.now
  end

  def self.stop
    $redis.set "auto_assign:stats:running", false
    $redis.set "auto_assign:stats:stop_at", Time.now
    Sidekiq.logger.info "当前自动分配服务已经关闭 at #{Time.now}"
  end

  def self.start
    $redis.set "auto_assign:stats:running", true
    $redis.set "auto_assign:stats:start_at", Time.now
    
    Sidekiq.logger.info "当前自动分配服务已经开启 at #{Time.now}"
    AutoAssignWorker.perform_async
  end

  def self.stats
    { 
      :running => self.running?,
      :start_at => $redis.get("auto_assign:stats:start_at"),
      :stop_at => $redis.get("auto_assign:stats:stop_at"),
      :counter => $redis.get("auto_assign:stats:counter"),
      :dispatching => $redis.get("auto_assign:stats:dispatching"),
      :dispatch_start_at => $redis.get("auto_assign:stats:dispatch_start_at"),
      :dispatch_stop_at => $redis.get("auto_assign:stats:dispatch_stop_at")
    }
  end

  def self.auto_assignable?(aa_case)
    if !aa_case.owner.nil?
      Sidekiq.logger.info "任务 #{aa_case.no} 已经有owner,不能自动分配 at #{Time.now}"
      return false 
    end

    if !aa_case.dispatcher.nil? 
      Sidekiq.logger.info "任务 #{aa_case.no} 已经有dispatcher,不能自动分配 at #{Time.now}"
      return false 
    end

    if aa_case.from_province.blank? && aa_case.from_city.blank? && aa_case.from_region.blank?
      Sidekiq.logger.info "任务 #{aa_case.no} 没有地址信息,不能自动分配 at #{Time.now}"
      return false
    end

    if ClientService.where("name = :name and disabled_at is null and can_auto_assign = true", :name => aa_case.client_service_name).exists?
      Sidekiq.logger.info "任务 #{aa_case.no} 业务来源允许自动分配 at #{Time.now}"

      if District.where("province = :province and city = :city and region = :region", :province => aa_case.from_province, :city => aa_case.from_city, :region => aa_case.from_region).exists?
        if aa_case.from_province.blank?
          Sidekiq.logger.info "任务 #{aa_case.no} 没有省份信息,可以自动分配 at #{Time.now}"
          return true 
        end

        if !aa_case.from_province.blank? && aa_case.from_city.blank? && District.where("province = :province and can_auto_assign = true", :province => aa_case.from_province).exists?
          Sidekiq.logger.info "任务 #{aa_case.no} 没有市信息,但是该省份可以自动分配 at #{Time.now}"
          return true
        end

        if !aa_case.from_province.blank? && !aa_case.from_city.blank? && aa_case.from_region.blank? && District.where("province = :province and city = :city and can_auto_assign = true", :province => aa_case.from_province, :city => aa_case.from_city).exists?
          Sidekiq.logger.info "任务 #{aa_case.no} 没有区域信息,但是该省份和市可以自动分配 at #{Time.now}"
          return true
        end

        if !aa_case.from_province.blank? && !aa_case.from_city.blank? && !aa_case.from_region.blank? && District.where("province = :province and city = :city and region = :region and can_auto_assign = true", :province => aa_case.from_province, :city => aa_case.from_city, :region => aa_case.from_region).exists?
          Sidekiq.logger.info "任务 #{aa_case.no} 区域信息完整,可以自动分配 at #{Time.now}"
          return true
        end
      else
        #省市区找不到记录,看省市是否有记录
        #如果找到省市,配置成true,那就可以,否则就false
        #如果找不到省市,看是否有省记录
        #如果找到省,配置成true,那就可以,否则就false
        Sidekiq.logger.info "任务 #{aa_case.no} 无法找到对应的行政区域 at #{Time.now}"
        
        if District.where("province = :province and city = :city", :province => aa_case.from_province, :city => aa_case.from_city).exists?
          # 不写到一起
          if District.where("province = :province and city = :city and can_auto_assign = true", :province => aa_case.from_province, :city => aa_case.from_city).exists?
            Sidekiq.logger.info "任务 #{aa_case.no} 无法找到区,但是省市可以找到,并且可以自动分配 at #{Time.now}"
            return true
          end
        else
          if District.where("province = :province and can_auto_assign = true", :province => aa_case.from_province).exists?
            Sidekiq.logger.info "任务 #{aa_case.no} 无法找到市,但是省可以找到,并且可以自动分配 at #{Time.now}"
            return true
          end
        end

      end

    end
    Sidekiq.logger.info "任务 #{aa_case.no} 不符合任何可以自动分配的条件 at #{Time.now}"
    return false
  end

  def self.can_assign_to_at_this_time?(user)
    if UserOnlineManager.connections_count_of(user) == 0 || UserOnlineManager.status_of(user) != "在线"
      Sidekiq.logger.info "用户 #{user.no} 当前连接数为 #{UserOnlineManager.connections_count_of(user)} 状态为 #{UserOnlineManager.status_of(user)} ,不能分配 at #{Time.now}"
      return false
    else
      if self.last_assigned_of(user).nil? || (Time.now - self.last_assigned_of(user)).to_i >= user.auto_assign_interval.to_i
        Sidekiq.logger.info "用户 #{user.no} 离上次分配任务时间满足条件,可以分配 at #{Time.now}"
        return true
      else
        Sidekiq.logger.info "用户 #{user.no} 离上次分配任务时间不满足条件,不能分配 at #{Time.now}"
        return false
      end
    end
  end

  def self.history_of(user)
    $redis.hgetall "users:#{user.id}:assign_history"
  end

  def self.logs
    $redis.hgetall "auto_assign:logs:assign_history"
  end
end