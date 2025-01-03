class ImagesController < ApplicationController
  def index
  end

  def create
    @image = Image.new(image_params)
    if @image.save
      render json: { status: "success", image_url: url_for(@image.file) }
    else
      render json: { status: "error", message: @image.errors.full_messages.join(", ") }
    end
  end

  def process_edge
    begin
      Rails.logger.debug "Starting edge detection process"

      original_image = MiniMagick::Image.read(params[:image].tempfile)
      processed_image = process_edge_detection(original_image, params[:threshold].to_i)

      processed_base64 = Base64.strict_encode64(processed_image.to_blob)
      render json: {
        status: "success",
        processed_image: "data:image/png;base64,#{processed_base64}"
      }
    rescue => e
      Rails.logger.error "Edge detection error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { status: "error", message: "画像処理中にエラーが発生しました" }
    end
  end

  private

  def image_params
    params.require(:image).permit(:file)
  end

  def process_edge_detection(image, threshold)
    width = image.width
    height = image.height
    pixels = image.get_pixels
    new_pixels = Array.new(height) { Array.new(width) }

    (0...height).each do |y|
      (0...width).each do |x|
        new_pixels[y][x] = [ 255, 255, 255 ]

        if x < (width - 1) && y < (height - 1)
          current = pixels[y][x]
          right = pixels[y][x + 1]
          bottom = pixels[y + 1][x]

          if pixel_difference?(current, right, threshold) ||
             pixel_difference?(current, bottom, threshold)
            new_pixels[y][x] = [ 0, 0, 0 ]
          end
        end
      end
    end

    result = MiniMagick::Image.create do |tmp|
      tmp.format "png"
      tmp.write(pixels_to_blob(new_pixels))
    end

    result
  end

  def pixel_difference?(pixel1, pixel2, threshold)
    (pixel1[0] - pixel2[0]).abs > threshold ||
    (pixel1[1] - pixel2[1]).abs > threshold ||
    (pixel1[2] - pixel2[2]).abs > threshold
  end

  def pixels_to_blob(pixels)
    height = pixels.length
    width = pixels[0].length

    image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::WHITE)

    height.times do |y|
      width.times do |x|
        r, g, b = pixels[y][x]
        image[x, y] = ChunkyPNG::Color.rgb(r, g, b)
      end
    end

    image.to_blob
  end
end
