class PinganPhoto < ActiveRecord::Base
  include Searchable
  quick_search :aa_case_no
  belongs_to :aa_case
  belongs_to :aa_rescue
  paginates_per 10
  def set_data(media_file,attachment_file)
    if media_file
      media_file.each do |media_hash|
        media = Wechat::WechatMedia.find_by_id(media_hash[0])
        set_photo_by_wechat_media(media_hash[1],media)
      end
    end

    if attachment_file
      attachment_file.each do |attachment_hash|
        attachment = AaRescueAttachment.find_by_id(attachment_hash[0])
        set_photo_by_aa_rescue_attachment(attachment_hash[1],attachment)
      end
    end
    Rails.logger.info self
  end

  def set_photo_by_wechat_media(num, wechat_media)
    self.send("photo#{num}_url=",wechat_media.media_file.url)
    self.send("photo#{num}_name=",wechat_media.media_file.identifier)
    self.send("photo#{num}_created_at=",wechat_media.created_at)
  end

  def set_photo_by_aa_rescue_attachment(num, aa_rescue_attachment)
    self.send("photo#{num}_url=",aa_rescue_attachment.attachment.url)
    self.send("photo#{num}_name=",aa_rescue_attachment.attachment.identifier)
    self.send("photo#{num}_created_at=",aa_rescue_attachment.created_at)
  end
end 