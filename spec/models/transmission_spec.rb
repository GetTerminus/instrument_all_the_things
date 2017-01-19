require 'spec_helper'

module InstrumentAllTheThings
  describe Transmission do
    around do |example|
      InstrumentAllTheThings.active_tags.clear
      InstrumentAllTheThings.with_tags('foo') { example.call }
    end

    let(:instance) { Transmission.new('localhost', 8125) }
    %i{decrement increment }.each do |meth|
      describe "##{meth}" do
        it "auto appends the active tags" do
          expect(instance).to receive(:send_stats).with(anything, anything, anything, a_hash_including(tags: ['foo']))
          instance.send(meth, 'metric')
        end

        it "allows extra tags to be sent" do
          expect(instance).to receive(:send_stats).with(anything, anything, anything, a_hash_including(tags: match_array(['foo', 'bar'])))
          instance.send(meth, 'metric', tags: ['bar'])
        end

        it "allows specific global tags to be removed", runme: true do
          expect(instance).to receive(:send_stats).with(anything, anything, anything, a_hash_including(tags: match_array(['bar'])))
          instance.send(meth, 'metric', tags: ['bar'], skip_global_tags: true)
        end
      end
    end

    %i{count gauge histogram set timing}.each do |meth|
      describe "##{meth}" do
        it "auto appends the active tags" do
          expect(instance).to receive(:send_stats).with(anything, anything, anything, a_hash_including(tags: ['foo']))
          instance.send(meth, 'metric', 1)
        end

        it "allows extra tags to be sent" do
          expect(instance).to receive(:send_stats).with(anything, anything, anything, a_hash_including(tags: match_array(['foo', 'bar'])))
          instance.send(meth, 'metric', 1, tags: ['bar'])
        end

        it "allows specific global tags to be removed", runme: true do
          expect(instance).to receive(:send_stats).with(anything, anything, anything, a_hash_including(tags: match_array(['bar'])))
          instance.send(meth, 'metric', 1, tags: ['bar'], skip_global_tags: true)
        end
      end
    end
  end
end
