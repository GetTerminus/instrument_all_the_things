require 'spec_helper'
require 'ddtrace'

describe "Method instumentation" do
  let(:fake_trace) { double(Datadog::Tracer) }

  before do
    stub_const("TestModule::TestClass", klass)
  end

  around do |ex|
    InstrumentAllTheThings.config.tracer = InstrumentAllTheThings.config.tracer.tap do
      InstrumentAllTheThings.config.tracer = fake_trace
      ex.run
    end
  end

  let(:klass) do
    Class.new do
      include InstrumentAllTheThings::Methods

      instrument trace: { as: 'hello' }
      def foo
        123
      end

      instrument trace: { as: 'bar.hello', service: 'baz' }
      def self.bar
        456
      end
    end
  end

  let(:instance) { klass.new }

  it 'provides basic tracing' do
    expect(fake_trace).to receive(:trace).with('hello', an_instance_of(Hash)) do |&blk|
      blk.call
    end
    expect(fake_trace).to receive(:trace).with('bar.hello', an_instance_of(Hash)) do |&blk|
      blk.call
    end

    expect(instance.foo).to eq 123
    expect(klass.bar).to eq 456
  end

  it 'logs a warning if tracing is requested with no tracer set' do
    faux_logger = Logger.new(STDOUT)
    InstrumentAllTheThings.config.tracer = nil
    InstrumentAllTheThings.config.logger = faux_logger

    expect(faux_logger).to receive(:warn) do |&blk|
      expect(blk.call()).to include "Requested tracing on foo"
    end
    expect(instance.foo).to eq 123
  end

  context "tagging" do
    let(:klass) do
      Class.new do
        include InstrumentAllTheThings::Methods

        instrument trace: { as: 'hello' }, tags: ['foo:bar']
        def foo
          123
        end

        instrument trace: { as: 'bar.hello', tags: {baz: 'nitch'} }, tags: ['wassup:bar', 'baz:123']
        def self.bar
          456
        end
      end
    end

    it "tags traces" do
      expect(fake_trace).to receive(:trace).with(
        'hello',
        a_hash_including(tags: a_hash_including({'foo' => 'bar'}))
      ) do |&blk|
        blk.call
      end

      expect(fake_trace).to receive(:trace).with(
        'bar.hello',
        a_hash_including(tags: a_hash_including({'baz' => 'nitch', 'wassup' => 'bar'}))
      ) do |&blk|
        blk.call
      end

      instance.foo
      klass.bar
    end

    it "persists return values" do
      expect(fake_trace).to receive(:trace) do |&blk|
        blk.call
      end
      expect(fake_trace).to receive(:trace) do |&blk|
        blk.call
      end

      expect(instance.foo).to eq 123
      expect(klass.bar).to eq 456
    end
  end
end
