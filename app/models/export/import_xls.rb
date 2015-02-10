require 'spreadsheet'
class Export::ImportXls
  def self.import(file)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)


    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
    file_path = OPTIONS["aa_cases_import_xls_path"] + timestamp + "_cases.xls"

    dirname = File.dirname(file_path)
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet
    sheet1.row(0).concat(["no"])
    sheet1.row(0).concat(header)
    # 0:no 1:aa_vendor 2:car_license_no 
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      p row
      no = spreadsheet.row(i)[0].to_i.to_s[-6,6]
      aa_case = AaCase.joins(:aa_rescue).where("right(aa_cases.no,6) = ? and aa_rescues.aa_vendor_name = ? and replace(aa_cases.car_license_no,'-','') = ?",no,spreadsheet.row(i)[1],spreadsheet.row(i)[2]).first
      if aa_case
        ary =  row.values.unshift(aa_case.no) 
        sheet1.row(i).concat(ary) 
      end
    end
 
    book.write file_path

    return file_path
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Roo::Csv.new(file.path, nil, :ignore)
    when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end