require 'erb'
require 'zip'
require 'fileutils'

class Export::ExportXls
  attr_accessor :models, :template_file_path

  def initialize(models, template_file_path)
    @models = models
    @template_file_path = template_file_path
  end

  def render_template
    erb = ERB.new(File.read(template_file_path)).result(binding)
  end

  def gzip(file_name)
    stringio = Zip::OutputStream::write_buffer(StringIO.new('')) do |zio|
      zio.put_next_entry(file_name)
      zio.write render_template
    end
    stringio.rewind
    binary_data = stringio.sysread
    stringio.close
    return binary_data
  end

  #this is whenever worker
  def self.create_aa_cases_zip
    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    file_path = OPTIONS["aa_cases_export_zip_path"] + timestamp + "_cases.zip"
    dir_exist(file_path)

    #添加当日文件
    File.open(file_path,"w+") do |file|
      stringio = Zip::OutputStream::write_buffer(StringIO.new('')) do |zio|
        OPTIONS["aa_cases_export_day"].times do |index|
        # 5.times do |index| #test row
          excel_file_name = (Time.now - (index+1).days).strftime('%Y-%m-%d')+ "_cases.xls"
          export_xls = Export::ExportXls.new(AaCase.where("created_at between DATE_FORMAT(SUBDATE(NOW(),#{index+2}), '%y-%m-%d 16:00:00') and DATE_FORMAT(SUBDATE(NOW(),#{index+1}), '%y-%m-%d 16:00:00')"
            ), "#{Rails.root}/app/views/aa_cases/export.xls.erb")
          zio.put_next_entry(excel_file_name)
          zio.write export_xls.render_template 
        end
      end
      stringio.rewind
      file.write stringio.sysread
      stringio.close
    end

    export_file = ExportFile.create_file(timestamp + "_cases.zip",file_path,"zip","AaCase")
    #Notifier.delay.welcome(current_user)
    Notifier.delay.download_export_file(export_file)
  end

  def self.create_aa_cases_zip_aly
    #添加当日文件
 
    stringio = Zip::OutputStream::write_buffer do |zio|
      5.times do |index|
        excel_file_name = (Time.now - (index+1).days).strftime('%Y-%m-%d')+ "_cases.xls"
        export_xls = Export::ExportXls.new(AaCase.export, "#{Rails.root}/app/views/aa_cases/export.xls.erb")
        zio.put_next_entry(excel_file_name)
        zio.write export_xls.render_template 
      end
    end
    stringio.rewind

    StringIO.class_eval { def original_filename; Time.now.strftime('%Y-%m-%d_%H-%M-%S') + "_cases.zip"; end }
    ExportFile.create_file(Time.now.strftime('%Y-%m-%d_%H-%M-%S') + "_cases.zip",stringio,"zip","AaCase")
  end



  def loop_send(object, methods, num = 0 )
    unless object.send(methods[num]).nil?
      num < methods.length - 1 ? loop_send(object.send(methods[num]),methods,num = num + 1 ) : object.send(methods[num])   
    end  
  end


  def self.dir_exist(file_path)
    dirname = File.dirname(file_path)
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
  end
end