# -*- encoding : utf-8 -*-

module GrandCloud

  class Video

    def get id
      json = common_request do
        Base.send_request({:method => 'get', :uri => "/video/#{id}"})
      end
      wrap_object(json['video'])
    end

    #u must start an event loop when u uploading an media
    def run
      EM.run { yield }
    end

    # upload is an async method
    def upload title, file_path, &block
      file = File.new(file_path)
      creation = Base.send_request({
        :method => 'post',
        :uri => '/video',
        :additional_params => {
          :Title => title
        }
      })
      creation.callback do 
        rep = JSON.parse(creation.response)
        puts rep
        req = Base.file_upload({
          :method => 'post',
          :uri => '/vmsUpload.htm',
          :url => rep['uploadUrl'],
          :file_path => file_path,
          :host => rep['uploadUrl'].gsub(/^http:\/\/(.+)\/.+/, '\1'),
          :request_params => {
            :sid => rep['sid'],
            :cfrom => 'client',
            :filesize => file.size,
            :ext => File.extname(file)
          }
        })
        callback(req, block.to_proc, rep.select{|k, v| k =='sid' || k =='vid'})
      end
      creation.errback do 
        puts 'requesting error...'
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
    end

    def destory id
      json = common_request do 
        Base.send_request({
          :method => 'delete',
          :uri => "/videos/#{id}"
        })
      end
      json['returnValue']
    end

    def list
      json = common_request do
        Base.send_request({:method => 'get', :uri => "/videos"})
      end
      json['videoSet'].map{|v|[wrap_object(v)]}
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
    end

    def get_programs
      common_request do
        Base.send_request({
          :method => 'get',
          :uri => '/programs'
        })
      end
    end

    #15622
    def get_default_program_id
      result = get_programs['programSet'].select{|a| a['programName'] == '默认方案'}
      result.empty? ? 0 : result[0]['programId']
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
        func.call(rep) if func
        EM.stop
      end
      req.errback do
        response.fail(nil)
        func.call("{errors:[{'message': 'Requested error...'}]}".to_json) if func
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
