# -*- encoding : utf-8 -*-

require 'spec_heler'
require 'debugger'

module GrandCloud

  #21430166
  $video_id = nil

  describe Video do 

    before :all do
      @video = GrandCloud::Video.new
    end

    context "#video" do

      it 'should upload video' do
        @video.run do
          puts 'start uploading, please wait...'
          @video.upload('spec_video', '/tmp/test.mp4'){ |rep|
            $video_id = rep['vid']
            rep['code'].should == 200
          }
        end
      end

      it "should get video detail" do
        @video.get($video_id).vid.should_not nil
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
        @video.update($video_id, 'test foo', 'Foo Bar').should == true
      end

      it 'should delete video successfully' do
        @video.destory($video_id).should == true
      end

    end
  end
end
