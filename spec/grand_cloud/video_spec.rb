# -*- encoding : utf-8 -*-

require 'spec_heler'
require 'debugger'

module GrandCloud

  describe Video do 

    before :all do
      @video = GrandCloud::Video.new
    end

    context "#video" do

      it "should get video detail" do
        @video.get(21430166).vid.should == 21430166
      end

      it 'should list video size greater than zero' do
        @video.list.size.should > 0
      end

      it 'should list programs greater than zero' do
        @video.get_programs.size.should > 0
      end

      it 'should update video successfully' do
        @video.update(21430166, 'bady', 'Cute baby').should == true
      end

      it 'should upload video' do
        @video.run do
          puts 'start uploading, please wait...'
          @video.upload('Automatic', '/tmp/Automatic.mp3'){ |rep| 
            rep['code'].should == 200
          }
        end
      end

    end
  end
end
