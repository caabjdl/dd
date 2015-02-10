class Notifier < ActionMailer::Base
  include Sidekiq::Worker
  default from: "webapp@caa.com.cn"

  def welcome(user)
    @user = user
    mail(to: user.email,subject: "CAA调度系统用户注册")
  end

  def download_export_file(export_file)
    @export_file = export_file
    users = User.where(:subscribe_export => true).pluck(:email).join(";")
    mail(to: users,subject: "调度任务导出数据")
  end

  def handle_return_pingan_error(no, msg)
    @no = no
    @msg = msg
    mail(to: OPTIONS["handle_pingan_error_mail"], subject: "任务#{@no}回传状态5异常")
  end
end
