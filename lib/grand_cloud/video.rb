
module GrandCloud
  class Video

    class << self

      #u must start an event loop when u uploading an media
      def run
        EM.run { yield }
      end

      def get id
        common_request do
          Base.send_request({:method => 'get', :uri => "/video/#{id}"})
        end
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
          callback(req, block.to_proc)
        end
        creation.errback do 
          puts 'requesting error...'
        end
      end

      def update id, title, desc
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

      def destory id
        common_request do 
          Base.send_request({
            :method => 'delete',
            :uri => "/videos/#{id}"
          })
        end
      end

      def list
        common_request do
          Base.send_request({:method => 'get', :uri => "/videos"})
        end
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

      private

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

    end
  end
end
