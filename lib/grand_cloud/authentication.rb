

module GrandCloud

  DEFAULT_HOST_URL = "api.ku6vms.com"

  class Authentication
    attr_reader :secret_access_key, :snda_access_key_id

    def initialize(secret_access_key, snda_access_key_id)
      @secret_access_key, @snda_access_key_id = secret_access_key, snda_access_key_id
    end

    def create_signature options
      secret_access_key = @secret_access_key
      http_verb = options[:method].to_s.upcase
      host = options[:host] || DEFAULT_HOST_URL
      uri = options[:uri] || ''
      protocal_params = options[:protocal_params]

      partial_signature = "#{http_verb}\n#{host}\n#{uri}"
      partial_signature <<  "\n#{protocal_params}" unless protocal_params.nil?
      digest = OpenSSL::Digest::Digest.new("sha256")
      hmac = OpenSSL::HMAC.digest(digest, secret_access_key, partial_signature)

      Base64.encode64(hmac).chomp
    end

    def generate_protocol_params additional_params
      {
        :Expires => Time.now.tomorrow.ago(3600*23).to_s(:db),
        #:Expires => '2013-07-03 00:00:00',
        :SignatureMethod => 'HmacSHA256',
        :SndaAccessKeyId => @snda_access_key_id,
        :Timestamp => Time.now.to_s(:db)
        #:Timestamp => '2013-07-02 11:36:11'
      }.merge!(additional_params ? additional_params : {}).sort.collect{|k,v| "#{k}=#{v}"}.join('&')
    end

    def generate_upload_params request_params
      request_params.merge!({
        :SignatureMethod => 'HmacSHA256',
        :SndaAccessKeyId => @snda_access_key_id
      }).sort.collect{|k,v| "#{k}=#{v}"}.join('&')
    end

  end

end
