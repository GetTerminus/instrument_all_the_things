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

      instrument trace: { as: 'bar.hello' }
      def self.bar
        456
      end
    end
  end

  let(:instance) { klass.new }

  it 'provides basic tracing' do
    expect(fake_trace).to receive(:trace).with('hello', {}) do |&blk|
      blk.call
    end
    expect(fake_trace).to receive(:trace).with('bar.hello', {}) do |&blk|
      blk.call
    end

    expect(instance.foo).to eq 123
    expect(klass.bar).to eq 456
  end

end
