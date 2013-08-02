module GrandCloud
  class Video

    def get_video_detail id
      common_request do
        Base.send_request({:method => 'get', :uri => "/video/#{id}"})
      end
    end

    def create_video title
      common_request do
        req = Base.send_request({
          :method => 'post',
          :uri => '/video',
          :additional_params => {
            :Title => title
          }
        })
      end
    end

    def upload_video sid, upload_url, file_path, &block
      file = File.new(file_path)
      EM.run do 
        req = Base.file_upload({
          :method => 'post',
          :uri => '/vmsUpload.htm',
          :url => upload_url,
          :file_path => file_path,
          :host => upload_url.gsub(/^http:\/\/(.+)\/.+/, '\1'),
          :request_params => {
            :sid => sid,
            :cfrom => 'client',
            :filesize => file.size,
            :ext => File.extname(file)
          }
        })
        callback(req, block.to_proc)
      end
    end

    def update_video id, title, desc
      common_request do
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
    end

    def delete_video id
      common_request do 
        Base.send_request({
          :method => 'delete',
          :uri => "/videos/#{id}"
        })
      end
    end

    def list_videos
      common_request do
        Base.send_request({:method => 'get', :uri => "/videos"})
      end
    end

    def import_video ku6vid
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

    def publish_video id, programId
      common_request do 
        Base.send_request({
          :method => 'get',
          :uri => "/video/#{id}/publication",
          :additional_params => {
            :ProgramId => programId
          }
        })
      end
    end

    def get_programs
      common_request do
        Base.send_request({
          :method => 'get',
          :uri => '/programs'
        })
      end
    end

    def callback req, func=nil
      response = EM::DefaultDeferrable.new
      req.callback do
        rep = JSON.parse(req.response)
        if rep['errors']
          response.fail(rep)
        else
          response.succeed(rep)
        end
        func.call(req.response) if func
        EM.stop
      end
      req.errback do
        response.fail(nil)
        func.call("{errors:[{'message': 'Requested error...'}]}".to_json) if func
        EM.stop
      end
      response
    end

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

  end
end
