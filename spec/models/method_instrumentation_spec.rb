require 'spec_helper'

describe "Method instumentation" do
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings::Methods

      instrument
      def foo
      end

      instrument
      def self.bar
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
end
