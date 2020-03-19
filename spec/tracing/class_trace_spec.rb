# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'class method tracing' do
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
    klass.foo.tap { flush_traces }
  end

  before do
    klass.instrument(trace: trace_options)
    klass.define_singleton_method(:foo) { |*_i| 123 }
  end

  it 'creates a trace with defaults' do
    expect { call_traced_method }.to change {
      emitted_spans(
        filtered_by: {
          name: 'method.execution',
          service: '',
          resource: 'KlassName#foo',
          type: '',
        },
      ).length
    }.by(1)
  end

  it 'returns the function data' do
    expect(call_traced_method).to eq 123
  end

  describe 'when disabled' do
    let(:trace_options) { false }

    it 'respects the configuration' do
      expect { call_traced_method }.not_to(change { emitted_spans.length })
    end
  end

  describe 'when the service name is configured' do
    let(:trace_options) { { service: 'foobar' } }

    it 'respects the configuration' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: { service: 'foobar' },
        ).length
      }.by(1)
    end
  end

  describe 'when the resource name is configured' do
    let(:trace_options) { { resource: 'foobar' } }

    it 'respects the configuration' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: { resource: 'foobar' },
        ).length
      }.by(1)
    end
  end

  describe 'when the type is configured' do
    let(:trace_options) { { span_type: 'ddd' } }

    it 'respects the configuration' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: { type: 'ddd' },
        ).length
      }.by(1)
    end
  end

  describe 'inheritance' do
    let(:sub_klass) do
      Class.new(klass) do
        def self.to_s
          'SubKlassName'
        end
      end
    end

    subject(:call_traced_method) do
      sub_klass.foo
      flush_traces
    end

    it 'emits spans with the subklass name' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: {
            name: 'method.execution',
            service: '',
            resource: 'SubKlassName#foo',
            type: '',
          },
        ).length
      }.by(1)
    end
  end
end
