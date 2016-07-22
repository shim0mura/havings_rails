module CarrierwaveBase64Uploader
  extend ActiveSupport::Concern

  # http://blog.hello-world.jp.net/ruby/2281/

  private

  def base64_conversion(uri_str, filename = Time.now.to_i.to_s)
    image_data = split_base64(uri_str)
    image_data_string = image_data[:data]
    image_data_binary = Base64.decode64(image_data_string)

    temp_img_file = Tempfile.new(filename)
    temp_img_file.binmode
    temp_img_file << image_data_binary
    temp_img_file.rewind

    img_params = {:filename => "#{filename}.#{image_data[:extension]}", :type => image_data[:type], :tempfile => temp_img_file}
    ActionDispatch::Http::UploadedFile.new(img_params)
  end

  def split_base64(uri_str)
    if uri_str.match(/data:(.*?);(.*?),(.*)/m)
      uri = Hash.new
      uri[:type] = $1
      uri[:encoder] = $2
      uri[:data] = $3
      uri[:extension] = $1.split('/')[1]
      return uri
    else
      return nil
    end
  end

  def is_base64_data?(uri_str)
    return split_base64(uri_str) ? true : false
  end

end
