# -*- encoding : utf-8 -*-
require 'logger'

module GrandCloud

  class Video

    def get id
      json = common_request do
        Base.send_request({:method => 'get', :uri => "/video/#{id}"})
      end
      wrap_object(json['DetailVideoResponse']['video'])
    rescue Error::ResponseError => e
      GrandCloud.logger.error(e)
      return nil
    end

    #u must start an event loop when u uploading an media
    def run
      EM.run { yield }
    end

    def create title, pass_encoding=false, &block
      creation = Base.send_request({
        :method => 'post',
        :uri => '/video',
        :additional_params => {
          :Title => title,
          :BypassEncoding => pass_encoding
        }
      })
      creation.callback { block.call(GrandCloud.nori.parse(creation.response)['CreateVideoResponse']) }

      creation.errback do 
        GrandCloud.logger.error("Error is: #{creation.error}, requesting error...")
        block.call(nil)
      end
    end

    # upload is an async method
    # you should pass an original_filename on options when you uploading a temp file
    def upload title, file, options={}, pass_encoding=false, &block
      return EM.stop if ((file.class == Tempfile) && (!options[:original_filename])) || !block_given?

      pn_file = Pathname(file)

      title = get_video_title(title, options[:original_filename], pn_file)
      extname = get_video_extname(options[:original_filename], pn_file)

      self.create(title, pass_encoding) do |rep| 

        return block.call(nil) unless rep

        GrandCloud.logger.warn(rep)

        req = Base.file_upload({
          :method => 'post',
          :uri => '/vmsUpload.htm',
          :url => rep['uploadUrl'],
          :pn_file => pn_file,
          :host => rep['uploadUrl'].gsub(/^http:\/\/(.+)\/.+/, '\1'),
          :request_params => {
            :sid => rep['sid'],
            :cfrom => 'client',
            :filesize => pn_file.size,
            :ext => extname
          },
          :timeout => {
            :inactivity_timeout => 0
          }

        })
        callback(req, block.to_proc, rep.select{|k, v| %W{sid vid}.include?(k)})
      end
    end

    def pull_by_vms title, download_url, &block 
      return EM.stop unless block_given?

      self.create(title) do |rep|

        return block.call(nil) unless rep

        GrandCloud.logger.warn(rep)

        req = Base.send_request({
          :method => 'post',
          :uri => '/video/urlupload',
          :additional_params => {
            :sid => rep['sid'],
            :videoUrl => CGI::escape(download_url),
            :uploadUrl => rep['uploadUrl'],
            :accessKey => Base.snda_access_key_id,
            :secretKey => Base.secret_access_key,
            :oneway => true
          },
          :timeout => {
            :inactivity_timeout => 0
          }

        })
        callback(req, block.to_proc, rep.select{|k, v| %W{sid vid}.include?(k)})
      end
    end

    def update id, title, desc
      json = common_request do
        Base.send_request({
          :method => 'put',
          :uri => "/video/#{id}",
          :request_params => {
            :body => {
              :Vid => id,
              :Title => title,
              :Description => desc
            }
          }
        })
      end
      json['ModifyVideoResponse']['return']
    rescue Error::ResponseError => e
      GrandCloud.logger.error(e)
      return false
    end

    def destory id
      json = common_request do 
        Base.send_request({
          :method => 'delete',
          :uri => "/videos/#{id}"
        })
      end
      json['RemoveVideosResponse']['return']
    rescue Error::ResponseError => e
      GrandCloud.logger.error(e)
      return false
    end

    def list
      json = common_request do
        Base.send_request({:method => 'get', :uri => "/videos"})
      end
      json['ListVideoResponse']['videoSet']['item'].map{|v| wrap_object(v) }
    rescue Error::ResponseError => e
      GrandCloud.logger.error(e)
      return []
    end

    def import_ku6 ku6vid
      common_request do
        Base.send_request({
          :method => 'get',
          :uri => '/videos/importation/ku6',
          :additional_params => {
            :Ku6vids => ku6vid
          }
        })
      end
    end

    def publish id, programId
      publish_attributes = %w(vid ku6vid publishedJavaScript publishedHtml publishedSwf)

      json = common_request do 
        Base.send_request({
          :method => 'get',
          :uri => "/video/#{id}/publication",
          :additional_params => {
            :ProgramId => programId
          }
        })
      end

      json = json['publication'].select {|k, v| publish_attributes.include?(k) }.inject({}) do |r, (k, v)|
        r.merge!(k => (v.is_a?(Hash) ? v['value'] : v))
      end
      wrap_object(json)
    rescue Error::ResponseError => e
      GrandCloud.logger.error(e)
      return nil
    end

    def get_programs
      common_request do
        Base.send_request({
          :method => 'get',
          :uri => '/programs'
        })
      end
    rescue Error::ResponseError => e
      GrandCloud.logger.error(e)
      return []
    end

    #15622
    def get_default_program_id
      programs = get_programs 
      unless programs.empty?
        result = programs['ListProgramsResponse']['programSet'].select{|a| a['programName'] == '默认方案'}
        result.empty? ? nil : result[0]['programId']
      else
        nil
      end
    rescue Error::ResponseError => e
      GrandCloud.logger.error(e)
      return nil
    end

    private

    def callback req, func=nil, additional_attributes=nil
      response = EM::DefaultDeferrable.new
      req.callback do
        rep = req.response.blank? ? {'code' => req.response_header.status} : GrandCloud.nori.parse(req.response)
        rep = JSON.parse(req.response) if rep.blank?
        if (rep['Response'] && rep['Response']['errors']) || rep['HR']
          response.fail(rep)
        else
          response.succeed(additional_attributes ? rep.merge!(additional_attributes) : rep)
        end
        raise Error::ResponseError.new(rep['Response']['errors']['message']) if rep['Response'] && ['Response']['errors']
        raise Error::ResponseError.new('Ku6vms Internal error ...') if rep['HR']
        func.call(rep) if func
        EM.stop
      end
      req.errback do
        response.fail(nil)
        raise Error::ResponseError.new("Error is #{req.error}, Maybe the network doesn't working")
        EM.stop
      end
      response
    end

    # mock a sysynchronous request
    def common_request
      result= ''
      EM.run do 
        callback(yield).callback do |rep|
          result = rep
        end.errback do |rep|
          result = rep
        end
      end
      result
    end

    #wrap object from json, please see the ku6vms document for the object attribute detail
    def wrap_object json
      json.inject(self) do |r, (k, v)|
        r.class.class_eval do; attr_accessor k; end
        r.__send__("#{k}=", v)
        r
      end
      self
    end

    def get_video_title title, original_filename, pn_file
      return title unless title.blank?
      original_filename ? File.basename(original_filename, File.extname(original_filename)) : pn_file.basename(pn_file.extname)
    end
  
    def get_video_extname original_filename, pn_file
      original_filename ? File.extname(original_filename) : pn_file.extname
    end

  end

end
