require 'spec_helper'

describe "Method instumentation" do
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings::Methods

      instrument tags: ['foo:bar']
      def foo
      end

      instrument tags: ->(*args) { ["magic:#{args[0]/5}"] }
      def dude(foo)
      end

      instrument tags: ->() { ["magic:mike"] }
      def hrm(foo)
      end

      instrument tags: ['foo:bar']
      def self.bar
      end

      instrument tags: ->() { ["magic:mike"] }
      def self.nitch(foo)
      end

      instrument tags: ->(*args) { ["magic:#{args[0]/5}"] }
      def self.baz(num)
      end
    end
  end

  let(:instance) { klass.new }

  it 'provides basic instrumetation' do
    expect(instance).to receive(:_instrument_method).with(:foo, [], anything)
    instance.foo
  end

  it "provides basic instrumentation at the class level" do
    expect(klass).to receive(:_instrument_method).with(:bar, [], anything)
    klass.bar
  end

  context "tagging" do
    it "allows an array of tags" do
      expect(instance).to receive(:with_tags).
        with(array_including(['foo:bar']))

      instance.foo
    end

    it "allows a proc to provide tags" do
      expect(instance).to receive(:with_tags).
        with(array_including(['magic:mike']))

      instance.hrm(15)
    end

    it "allows a proc to provide tags" do
      expect(instance).to receive(:with_tags).
        with(array_including(['magic:3']))

      instance.dude(15)
    end

    context "class based instrumentation" do
      it "allows an array of tags" do
        expect(klass).to receive(:with_tags).
          with(array_including(['foo:bar']))

        klass.bar
      end

      it "allows a proc to provide tags" do
        expect(klass).to receive(:with_tags).
          with(array_including(['magic:mike']))

        klass.nitch(15)
      end


      it "allows a proc to provide tags" do
        expect(klass).to receive(:with_tags).
          with(array_including(['magic:3']))

        klass.baz(15)
      end
    end
  end
end
