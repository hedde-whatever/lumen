require "image_processing/vips"

class ImageNormalizer
  MAX_DIMENSION = 3000
  JPEG_QUALITY  = 90

  # Resizes the image to fit within MAX_DIMENSION x MAX_DIMENSION and
  # converts it to JPEG. Returns a hash suitable for ActiveStorage#attach.
  def self.call(upload)
    processed = ImageProcessing::Vips
      .source(upload.tempfile)
      .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
      .convert("jpeg")
      .saver(quality: JPEG_QUALITY)
      .call

    {
      io:           processed,
      filename:     File.basename(upload.original_filename, ".*") + ".jpg",
      content_type: "image/jpeg"
    }
  end
end
