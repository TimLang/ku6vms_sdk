# -*- encoding : utf-8 -*-

require 'spec_heler'
require 'tempfile'
require 'debugger'

module GrandCloud

  module Rspec
    #21430166
    @@video_id = nil

    describe Video do 

      before :all do
        @video = GrandCloud::Video.new
      end

      def raise_common_request_exception
        @video.stubs(:common_request).raises(GrandCloud::Error::ResponseError, '')
      end

      context "#video must done successfully functions" do

        it "should pulled by ku6vms" do
          @video.run do
            @video.pull_by_vms('spec_pull_video', 'http://storage-huadong-1.sdcloud.cn/images.jiaoxuebang.com/MOV_0399.mp4?SNDAAccessKeyId=BH297OBMKFV0T2LO9MC189P2J&Expires=1377147099&Signature=JpbNOKlBc7SD4%2FYKIiPz8HJDHf4%3D'){ |rep|
              puts rep
              rep['code'].should == 202
            }
          end
        end

        it 'should upload video' do
          @video.run do
            GrandCloud.logger.info('start uploading, please wait...')
            @video.upload('spec_video', File.new('/tmp/test.mp4')){ |rep|
              @@video_id = rep['vid']
              rep['code'].should == 200
            }
          end
        end

        it "should upload while mocking a rails controller" do
          file_path = '/tmp/test.mp4'
          @video.run do
            GrandCloud.logger.info('start uploading, please wait...')
            temp_file = Tempfile.new('/tmp/Rack_tempfiles_0')
            temp_file.write(File.new(file_path).read)
            @video.upload('mock_tempfile_as_video', temp_file, {:original_filename => 'woce.mp4'}){ |rep|
              @@video_id = rep['vid']
              rep['code'].should == 200
            }
          end
        end

        it "should get video detail" do
          @video.get(@@video_id).vid.should_not nil
        end

        it 'should list video size greater than zero' do
          @video.list.size.should > 0
        end

        it 'should list video can get vid' do
          videos = @video.list
          videos.each do |v|
            v.vid.should_not nil
          end
        end

        it 'should list programs greater than zero' do
          @video.get_programs.size.should > 0
        end

        it 'should get default program id' do
          @video.get_default_program_id.should_not nil
        end

        it 'should update video successfully' do
          @video.update(@@video_id, 'test foo', 'Foo Bar').should == true
        end

        it 'should delete video successfully' do
          @video.destory(@@video_id).should == true
        end

      end

      context '#video must done failed functions' do

        it 'should return nil when getting video raise exception' do
          @video.get(nil).should == nil
        end

        it "should return false when updating video raise exception" do
          @video.update(nil, nil, nil).should == false 
        end

        it "should return nil when uploading video with a temp file without passed an original_filename" do
          file_path = '/tmp/test.mp4'
          nil.should == @video.run do
            GrandCloud.logger.info('start uploading, please wait...')
            temp_file = Tempfile.new('/tmp/Rack_tempfiles_0')
            temp_file.write(File.new(file_path).read)
            @video.upload('mock_tempfile_as_video', temp_file) {}
          end 
        end

        it "should return false when deleting video raise exception" do
          @video.destory(nil).should == false
        end

        it "should return empty array when listing videos raise exception" do
          raise_common_request_exception
          @video.list.should == []
        end

        it "should return empty array when getting programs raise exception" do
          raise_common_request_exception
          @video.get_programs.should == []  
        end

        it "should return nil when getting default program id raise exception" do
          raise_common_request_exception
          @video.get_default_program_id.should == nil
        end

        it "should return nil when publishing video raise exception" do
          @video.publish(nil, nil).should == nil
        end
      end

    end
  end
end
