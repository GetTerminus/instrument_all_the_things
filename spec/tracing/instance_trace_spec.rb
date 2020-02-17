# frozen_string_literal: true

require 'spec_helper'
require 'pry'

RSpec.describe 'instance method tracing' do
  let(:trace_options) { {} }
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings

      def self.to_s
        'KlassName'
      end
    end
  end

  subject(:call_traced_method) do
    klass.new.foo
    flush_traces
  end

  before do
    klass.instrument(trace: trace_options)
    klass.define_method(:foo) { |*i| }
  end

  it 'creates a trace with defaults' do
    expect { call_traced_method }.to change {
      emitted_spans(
        filtered_by: {
          name: 'method.execution',
          service: '',
          resource: 'KlassName.foo',
          type: '',
          meta: {}
        }
      ).length
    }.by(1)
  end

  describe 'when the service name is configured' do
    let(:trace_options) { { service: 'foobar' } }

    it 'respects the configuration' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: { service: 'foobar' }
        ).length
      }.by(1)
    end
  end

  describe 'when the resource name is configured' do
    let(:trace_options) { { resource: 'foobar' } }

    it 'respects the configuration' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: { resource: 'foobar' }
        ).length
      }.by(1)
    end
  end

  describe 'when the type is configured' do
    let(:trace_options) { { span_type: 'ddd' } }

    it 'respects the configuration' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: { type: 'ddd' }
        ).length
      }.by(1)
    end
  end
end
