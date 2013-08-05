
module GrandCloud

  module Base

    class << self
      attr_accessor :secret_access_key, :snda_access_key_id

      def send_request options
        auth = GrandCloud::Authentication.new(@secret_access_key, @snda_access_key_id)
        protocal_params = auth.generate_protocol_params options[:additional_params]

        signature = auth.create_signature({
          :method => options[:method],
          :uri => options[:uri],
          :protocal_params => protocal_params,
          :host => options[:host]
        })

        url = URI.escape((options[:url] || ("http://#{(options[:host] || DEFAULT_HOST_URL)+options[:uri]}")) + "?" + protocal_params)+'&Signature='+CGI::escape(signature)

        params = {:head => {:Accept => options[:header_accept] || 'application/json'}}
        params.merge!(options[:request_params]) if options[:request_params]
        EM::HttpRequest.new(url).send((options[:method] && options[:method].downcase) || "get", params)
      end

      def file_upload options
        auth = GrandCloud::Authentication.new(@secret_access_key, @snda_access_key_id)

        protocal_params = auth.generate_upload_params options[:request_params]
        signature = auth.create_signature({
          :method => options[:method],
          :uri => options[:uri],
          :host => options[:host],
          :protocal_params => protocal_params
        })

        url = URI.escape(options[:url] + "?" + protocal_params) + '&Signature=' + CGI::escape(signature)

        #multipart patch
        partfile = Part.new(
          :name => 'file',
          :filename => File.basename(options[:file_path]),
          :body => File.new(options[:file_path]).read
        )
        parts = [partfile]
        body = MultipartBody.new(parts)

        EM::HttpRequest.new(url).post(
          :head => {
            'content-type' => "multipart/form-data; boundary=#{body.boundary}"
          },
          :body => body.to_s
        )
      end

    end
  end
end

