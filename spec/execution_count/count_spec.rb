# frozen_string_literal: true

RSpec.describe 'execution counters' do
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings

      instrument execution_counts: true
      def bar
        'asdf'
      end

      instrument execution_counts: true
      def baz
        raise 'abcd'
      end

      def self.to_s
        'KlassName'
      end
    end
  end

  let(:instance) { klass.new }

  it 'logs the executions' do
    expect {
      instance.bar
    }.to change { counter_value('KlassName.instance_methods.bar.executed') }.from(0).to(1)
  end

  it 'counts and re-raises errors' do
    expect {
      instance.baz
    }.to change { counter_value('KlassName.instance_methods.baz.errored') }.from(0).to(1)
      .and raise_error 'abcd'
  end
end
