# encoding: utf-8
class UniqueNumberManager
  
  def self.lock!(model, column, value, ttl)
    unless $redis.exists "unique_number:#{model}:#{column}:#{value}"
      $redis.set "unique_number:#{model}:#{column}:#{value}", Time.now
      $redis.pexpire "unique_number:#{model}:#{column}:#{value}", ttl
      return true
    else
      return false
    end
  end

  def self.unlock!(model, column, value)
    $redis.del "unique_number:#{model}:#{column}:#{value}"
  end

  def self.locked?(model, column, value)
    $redis.exists "unique_number:#{model}:#{column}:#{value}"
  end

end