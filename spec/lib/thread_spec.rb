# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'instance method tracing' do
  let(:trace_options) { {} }
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings
      def self.to_s
        'KlassName'
      end

      instrument trace: true
      def async_method
        Thread.new_traced do
          noop
        end
      end

      def async_method_untraced
        Thread.new_traced do
          noop
        end
      end

      instrument trace: true
      def noop; end
    end
  end

  context 'untraced async_method' do
    subject(:call_traced_method) do
      klass.new.async_method_untraced
      sleep(0.1)
    end

    it 'creates a new thread with no errors' do
      expect { call_traced_method }.to_not raise_error
    end

    it 'creates a trace with defaults for the traced method' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: {
            name: 'method.execution',
            resource: 'KlassName.async_method_untraced',
            type: '',
          },
        ).length
      }.by(0).and change {
        emitted_spans(
          filtered_by: {
            name: 'method.execution',
            resource: 'KlassName.noop',
            type: '',
          },
        ).length
      }.by(1)
    end
  end

  context 'traced async_method' do
    subject(:call_traced_method) do
      klass.new.async_method
      sleep(0.1)
    end

    it 'creates a trace with defaults for both methods' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: {
            name: 'method.execution',
            resource: 'KlassName.async_method',
            type: '',
          },
        ).length
      }.by(1).and change {
        emitted_spans(
          filtered_by: {
            name: 'method.execution',
            resource: 'KlassName.noop',
            type: '',
          },
        ).length
      }.by(1)
    end

    it 'sets the parent_ids of the children spans properly and includes them in the same trace' do
      call_traced_method

      async_method_span = emitted_spans(
        filtered_by: {
          name: 'method.execution',
          resource: 'KlassName.async_method',
          type: '',
        },
      ).first

      method_execution_span = emitted_spans(
        filtered_by: {
          name: 'method.execution',
          resource: 'method.execution',
          type: nil,
        },
      ).first

      noop_method_span = emitted_spans(
        filtered_by: {
          name: 'method.execution',
          resource: 'KlassName.noop',
          type: '',
        },
      ).first

      expect(noop_method_span['parent_id']).to eq(method_execution_span['span_id'])
      expect(method_execution_span['parent_id']).to eq(async_method_span['span_id'])

      expect(noop_method_span['trace_id']).to eq(async_method_span['trace_id'])
    end
  end
end
