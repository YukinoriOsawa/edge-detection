class Image < ApplicationRecord
  has_one_attached :file
  validates :file, presence: true
  validate :acceptable_image

  private

  def acceptable_image
    return unless file.attached?

    unless file.byte_size <= 10.megabyte
      errors.add(:file, "サイズは10MB以下にしてください")
    end

    acceptable_types = [ "image/jpeg", "image/png" ]
    unless acceptable_types.include?(file.content_type)
      errors.add(:file, "はJPEGまたはPNG形式である必要があります")
    end
  end
end
