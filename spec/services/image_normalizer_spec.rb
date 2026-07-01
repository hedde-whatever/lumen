require "rails_helper"
require "tempfile"

RSpec.describe ImageNormalizer do
  def build_jpeg(width, height)
    file = Tempfile.new([ "test_image", ".jpg" ])
    Vips::Image.black(width, height).write_to_file(file.path)
    upload = instance_double(
      ActionDispatch::Http::UploadedFile,
      tempfile:          file,
      original_filename: "photo.jpg",
      content_type:      "image/jpeg"
    )
    [ upload, file ]
  end

  describe ".call" do
    it "returns a hash with io, filename, and content_type" do
      upload, file = build_jpeg(100, 100)
      result = ImageNormalizer.call(upload)

      expect(result).to include(:io, :filename, :content_type)
      expect(result[:content_type]).to eq("image/jpeg")
      expect(result[:filename]).to end_with(".jpg")
    ensure
      file.close!
    end

    it "resizes images larger than 3000px to fit within 3000x3000" do
      upload, file = build_jpeg(4000, 3500)
      result = ImageNormalizer.call(upload)

      image = Vips::Image.new_from_file(result[:io].path)
      expect(image.width).to be <= 3000
      expect(image.height).to be <= 3000
    ensure
      file.close!
    end

    it "preserves aspect ratio when resizing" do
      upload, file = build_jpeg(4000, 2000)
      result = ImageNormalizer.call(upload)

      image = Vips::Image.new_from_file(result[:io].path)
      expect(image.width.to_f / image.height).to be_within(0.01).of(2.0)
    ensure
      file.close!
    end

    it "does not upscale images smaller than 3000px" do
      upload, file = build_jpeg(800, 600)
      result = ImageNormalizer.call(upload)

      image = Vips::Image.new_from_file(result[:io].path)
      expect(image.width).to eq(800)
      expect(image.height).to eq(600)
    ensure
      file.close!
    end

    it "converts output to JPEG regardless of input format" do
      png_file = Tempfile.new([ "test_image", ".png" ])
      Vips::Image.black(100, 100).write_to_file(png_file.path)
      upload = instance_double(
        ActionDispatch::Http::UploadedFile,
        tempfile:          png_file,
        original_filename: "photo.png",
        content_type:      "image/png"
      )

      result = ImageNormalizer.call(upload)
      expect(result[:content_type]).to eq("image/jpeg")
      expect(result[:filename]).to end_with(".jpg")
    ensure
      png_file.close!
    end
  end
end
