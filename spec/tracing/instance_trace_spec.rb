# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'instance method tracing' do
  let(:trace_options) { {} }
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings
      attr_accessor :test_tag
      def initialize
        self.test_tag = 'cool_tag_bro'
      end

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
        },
      ).length
    }.by(1)
  end

  describe 'when disabled' do
    let(:trace_options) { false }

    it 'respects the configuration' do
      expect { call_traced_method }.not_to(change { emitted_spans.length })
    end
  end

  describe 'a config of true' do
    let(:trace_options) { true }

    it 'respects the configuration' do
      expect { call_traced_method }.to change {
        emitted_spans(
          filtered_by: {
            name: 'method.execution',
            service: '',
            resource: 'KlassName.foo',
            type: '',
          },
        ).length
      }.by(1)
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

  describe 'with tags' do
    let(:trace_options) { { tags: ['hey'] } }

    it 'passes the tags to metrics' do
      expect { call_traced_method }.to change {
        IATT.stat_reporter.emitted_values[:count].length
      }.by(1)
      expect(IATT.stat_reporter.emitted_values[:count]["#{klass}.instance_methods.foo.executed"].first[:tags]).to eq(['hey'])
    end

    context 'with an instance var in a proc' do
      let(:trace_options) { { tags: [-> { "some_stat:#{test_tag}" }] } }

      it 'evaluates the instance var in the proc and passes the tag to metrics' do
        expect { call_traced_method }.to change {
          IATT.stat_reporter.emitted_values[:count].length
        }.by(1)
        expect(IATT.stat_reporter.emitted_values[:count]["#{klass}.instance_methods.foo.executed"].first[:tags]).to eq(['some_stat:cool_tag_bro'])
        expect(IATT.stat_reporter.emitted_values[:timing]["#{klass}.instance_methods.foo.duration"].first[:tags]).to eq(['some_stat:cool_tag_bro'])
      end
    end

    context 'with a method argument in a proc' do
      let(:trace_options) { { tags: [->(args) { "log_args:#{args[0]}" }] } }
      it 'evaluates args to the method' do
        expect { klass.new.foo('hello') }.to change {
          IATT.stat_reporter.emitted_values[:count].length
        }.by(1)
        expect(IATT.stat_reporter.emitted_values[:count]["#{klass}.instance_methods.foo.executed"].first[:tags]).to eq(['log_args:hello'])
      end
    end

    context 'with a method keyword argument in a proc' do
      let(:trace_options) { { tags: [->(kwargs) { "log_args:#{kwargs[:my_arg]}" }] } }
      it 'evaluates args to the method' do
        expect { klass.new.foo(my_arg: 'hello') }.to change {
          IATT.stat_reporter.emitted_values[:count].length
        }.by(1)
        expect(IATT.stat_reporter.emitted_values[:count]["#{klass}.instance_methods.foo.executed"].first[:tags]).to eq(['log_args:hello'])
      end

      context 'when the argument doesnt exist' do
        let(:trace_options) { { tags: [->(garbage) { "log_args:#{garbage[:my_arg]}" }] } }
        it 'uses kwargs' do
          expect { klass.new.foo(my_arg: 'hello') }.to change {
            IATT.stat_reporter.emitted_values[:count].length
          }.by(1)
          expect(IATT.stat_reporter.emitted_values[:count]["#{klass}.instance_methods.foo.executed"].first[:tags]).to eq(['log_args:hello'])
        end
      end

      context 'with args and kwargs in a proc' do
        let(:trace_options) { { tags: [->(args, kwargs) { "all_args:#{args[0]},#{kwargs[:my_arg]}" }] } }
        it 'evaluates args to the method' do
          expect { klass.new.foo('norm_arg', my_arg: 'hello_kwarg') }.to change {
            IATT.stat_reporter.emitted_values[:count].length
          }.by(1)
          expect(IATT.stat_reporter.emitted_values[:count]["#{klass}.instance_methods.foo.executed"].first[:tags]).to eq(['all_args:norm_arg,hello_kwarg'])
        end
      end
    end
  end
end
