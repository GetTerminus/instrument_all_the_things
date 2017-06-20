require 'spec_helper'

describe "Method instumentation" do
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings::Methods

      instrument tags: ['foo:bar']
      def foo
        123
      end

      instrument tags: ->(*args) { ["magic:#{args[0]/5}"] }
      def dude(foo)
      end

      instrument tags: ->() { ["magic:mike"] }
      def hrm(foo)
      end

      instrument tags: ['foo:bar']
      def self.bar
        456
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
    expect(
      InstrumentAllTheThings.transmitter
    ).to receive(:increment).with("methods.count")

    expect(instance.foo).to eq 123
  end

  it "provides basic instrumentation at the class level" do
    expect(
      InstrumentAllTheThings.transmitter
    ).to receive(:increment).with("methods.count")

    expect(klass.bar).to eq 456
  end

  context "exceptions" do
    it 'reraises instance errors' do
      expect(instance).to receive(:_foo_without_instrumentation)
        .and_raise('Hi there')
      expect{ instance.foo }.to raise_error('Hi there')
    end

    it "provides basic instrumentation at the class level" do
      expect(klass).to receive(:_bar_without_instrumentation)
        .and_raise('dude')
      expect{ klass.bar }.to raise_error('dude')
    end

  end

  context "tagging" do
    it "allows an array of tags" do
      expect(klass._instrumentors['#foo']).to receive(:with_tags).
        with(array_including(['foo:bar']))

      instance.foo
    end

    it "allows a proc to provide tags" do
      expect(klass._instrumentors['#hrm']).to receive(:with_tags).
        with(array_including(['magic:mike']))

      instance.hrm(15)
    end

    it "allows a proc to provide tags" do
      expect(klass._instrumentors['#dude']).to receive(:with_tags).
        with(array_including(['magic:3']))

      instance.dude(15)
    end

    context "class based instrumentation" do
      it "allows an array of tags" do
        expect(klass._instrumentors['.bar']).to receive(:with_tags).
          with(array_including(['foo:bar']))

        klass.bar
      end

      it "allows a proc to provide tags" do
        expect(klass._instrumentors['.nitch']).to receive(:with_tags).
          with(array_including(['magic:mike']))

        klass.nitch(15)
      end


      it "allows a proc to provide tags" do
        expect(klass._instrumentors['.baz']).to receive(:with_tags).
          with(array_including(['magic:3']))

        klass.baz(15)
      end
    end
  end
end
