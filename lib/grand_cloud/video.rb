# -*- encoding : utf-8 -*-
require 'logger'

module GrandCloud

  class Video

    def get id
      json = common_request do
        Base.send_request({:method => 'get', :uri => "/video/#{id}"})
      end
      wrap_object(json['video'])
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
      creation.callback { block.call(JSON.parse(creation.response)) }

      creation.errback do 
        GrandCloud.logger.error('requesting error...')
      end
    end

    # upload is an async method
    def upload title, file, pass_encoding=nil, &block
      pn_file = Pathname(file)
      self.create(title.empty? ? pn_file.basename(pn_file.extname) : title, pass_encoding) do |rep| 

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
            :ext => pn_file.extname
          },
          :timeout => {
            :inactivity_timeout => 0
          }

        })
        callback(req, block.to_proc, rep.select{|k, v| %W{sid vid}.include?(k)})
      end
    end

    def pull_by_vms title, download_url, &block 
      self.create(title) do |rep|

        GrandCloud.logger.warn(rep)

        req = Base.send_request({
          :method => 'post',
          :uri => '/video/urlupload',
          :additional_params => {
            :sid => rep['sid'],
            :videoUrl => CGI::escape(download_url),
            :uploadUrl => rep['uploadUrl'],
            :accessKey => Base.snda_access_key_id,
            :secretKey => Base.secret_access_key
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
      json['returnValue']
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
      json['returnValue']
    rescue Error::ResponseError => e
      GrandCloud.logger.error(e)
      return false
    end

    def list
      json = common_request do
        Base.send_request({:method => 'get', :uri => "/videos"})
      end
      json['videoSet'].map{|v| wrap_object(v) }
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
        result = programs['programSet'].select{|a| a['programName'] == '默认方案'}
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
        rep = JSON.parse(req.response)
        if rep['errors']
          response.fail(rep)
        else
          response.succeed(additional_attributes ? rep.merge!(additional_attributes) : rep)
        end
        raise Error::ResponseError.new(rep['errors'][0]) if rep['errors']
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

  end

end
