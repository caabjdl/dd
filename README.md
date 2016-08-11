# dd
AA Case logging and service track tool
init configuration:
Need redis to support sidekiq
No more "Need mongodb for some log"
Check database.yml
Need aliyun OSS as storage for daily report export, check carrierwave serials configurations in config/initializers
Send SMS through sms_api, config server and account in config/initializers/sms_api.rb
More: Memcache config if want to use Mail server Clam server SMS configuration
