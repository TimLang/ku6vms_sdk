
require 'spec_heler'

module GrandCloud

  describe Video do 
    
    before :all do
      @video = GrandCloud::Video
    end

    context "#video" do
      
      it "should get video detail" do
        @video.get(21430166)['video']['vid'].should == 21430166
      end

      it 'should list video' do
        @video.list.size.should > 0
      end

      it 'should list programs' do
        @video.get_programs.size.should > 0
      end

      it 'should update video' do
        @video.update(21430166, 'bady', 'Cute baby')['returnValue'].should == true
      end

    end
  end
end
