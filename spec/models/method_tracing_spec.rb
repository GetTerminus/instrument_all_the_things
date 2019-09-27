# frozen_string_literal: true

require 'spec_helper'
require 'ddtrace'

describe 'Method instumentation' do
  let(:fake_trace) { double(Datadog::Tracer) }

  before do
    stub_const('TestModule::TestClass', klass)
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

      instrument trace: { resource: 'hrm', as: 'hello' }
      def foo
        123
      end

      instrument trace: { as: 'bar.hello', service: 'baz' }
      def self.bar
        456
      end

      instrument trace: true
      def hello; end

      instrument trace: true
      def self.hello; end
    end
  end

  let(:instance) { klass.new }
  let(:fake_span) { double(Datadog::Span) }
  before{ allow(fake_span).to receive(:set_tag) }


  it 'provides basic tracing' do
    expect(fake_trace).to receive(:trace).with('hello', a_hash_including(resource: 'hrm')) do |&blk|
      blk.call(fake_span)
    end
    expect(fake_trace).to receive(:trace).with('bar.hello', a_hash_including(resource: 'TestModule::TestClass.bar')) do |&blk|
      blk.call(fake_span)
    end

    expect(instance.foo).to eq 123
    expect(klass.bar).to eq 456
  end

  it 'adds a allocations tag' do
    allow(fake_trace).to receive(:trace).with('hello', a_hash_including(resource: 'hrm')) do |&blk|
      blk.call(fake_span)
    end

    expect(fake_span).to receive(:set_tag).with('allocation_increase', an_instance_of(Integer))
    expect(fake_span).to receive(:set_tag).with('page_increase', an_instance_of(Integer))
    instance.foo
  end


  it 'provides timing at the instance level' do
    expect(fake_trace).to receive(:trace).with('method.execution', a_hash_including(resource: 'TestModule::TestClass#hello'))

    instance.hello
    expect(get_timings('test_module.test_class.instance.hello.timing').values.length).to eq 1
  end

  it 'provides timing at the class level' do
    expect(fake_trace).to receive(:trace).with('method.execution', an_instance_of(Hash))

    klass.hello
    expect(get_timings('test_module.test_class.class.hello.timing').values.length).to eq 1
  end

  it 'assumes a default name for instance methods' do
    expect(fake_trace).to receive(:trace).with('method.execution', a_hash_including(resource: 'TestModule::TestClass#hello'))
    instance.hello
  end

  it 'assumes a default name for class methods' do
    expect(fake_trace).to receive(:trace).with('method.execution', an_instance_of(Hash))
    klass.hello
  end

  it 'logs a warning if tracing is requested with no tracer set' do
    faux_logger = Logger.new(STDOUT)
    InstrumentAllTheThings.config.tracer = nil
    InstrumentAllTheThings.config.logger = faux_logger

    expect(faux_logger).to receive(:warn) do |&blk|
      expect(blk.call).to include 'Requested tracing on foo'
    end
    expect(instance.foo).to eq 123
  end

  context 'when tracing a module' do
    before do
      stub_const('TestModule::SubModule', mod)
    end

    let(:mod) do
      Module.new do
        include InstrumentAllTheThings::Methods

        instrument trace: { service: 'baz' }
        def self.bar
          456
        end
      end
    end


    it 'provides basic tracing' do
      expect(fake_trace).to receive(:trace).with(
        'method.execution',
        a_hash_including(service: 'baz', resource: 'TestModule::SubModule.bar')
      ) do |&blk|
        blk.call(fake_span)
      end

      expect(TestModule::SubModule.bar).to eq 456
    end
  end

  context 'when exceptions are raised' do
    let(:klass) do
      Class.new do
        include InstrumentAllTheThings::Methods

        instrument trace: true
        def foo
          123
        end

        instrument trace: true
        def self.bar
          456
        end
      end
    end

    before do
      allow(fake_trace).to receive(:trace) do |&blk|
        blk.call
      end
    end

    describe 'instance methods' do
      before { allow(instance).to receive(:_foo_without_instrumentation).and_raise 'Omg Error!' }

      it 'counts exceptions' do
        expect do
          instance.foo
        rescue StandardError
          nil
        end.to change {
          get_counter('test_module.test_class.instance.foo.exceptions.count').total
        }.from(nil).to(1)
      end

      it 'no longer counts success' do
        expect do
          instance.foo
        rescue StandardError
          nil
        end.to_not change {
          get_counter('test_module.test_class.instance.foo.success.count').total
        }.from(nil)
      end
    end

    describe 'class methods' do
      before { allow(klass).to receive(:_bar_without_instrumentation).and_raise 'Omg Error!' }
      it 'counts exceptions' do
        expect do
          klass.bar
        rescue StandardError
          nil
        end.to change {
          get_counter('test_module.test_class.class.bar.exceptions.count').total
        }.from(nil).to(1)
      end

      it 'no longer counts success' do
        expect do
          klass.bar
        rescue StandardError
          nil
        end.to_not change {
          get_counter('test_module.test_class.class.bar.success.count').total
        }.from(nil)
      end
    end
  end

  context 'tagging' do
    let(:klass) do
      Class.new do
        include InstrumentAllTheThings::Methods

        instrument trace: { as: 'hello', include_parent_tags: true }, tags: ['foo:bar']
        def foo
          123
        end

        instrument trace: { as: 'bar.hello', tags: { baz: 'nitch' }, include_parent_tags: true }, tags: ['wassup:bar', 'baz:123']
        def self.bar
          456
        end

        instrument trace: { as: 'test' }
        def self.baz
          456
        end
      end
    end

    it 'drops parent tags' do
      InstrumentAllTheThings.with_tags('hrm:wassup') do
        expect(fake_trace).to receive(:trace).with(
          'test',
          a_hash_including(tags: {})
        ) do |&blk|
          blk.call(fake_span)
        end
      end

      klass.baz
    end

    it 'tags traces' do
      expect(fake_trace).to receive(:trace).with(
        'hello',
        a_hash_including(tags: a_hash_including('foo' => 'bar'))
      ) do |&blk|
        blk.call(fake_span)
      end

      expect(fake_trace).to receive(:trace).with(
        'bar.hello',
        a_hash_including(tags: a_hash_including('baz' => 'nitch', 'wassup' => 'bar'))
      ) do |&blk|
        blk.call(fake_span)
      end

      instance.foo
      klass.bar
    end

    it 'persists return values' do
      expect(fake_trace).to receive(:trace) do |&blk|
        blk.call(fake_span)
      end
      expect(fake_trace).to receive(:trace) do |&blk|
        blk.call(fake_span)
      end

      expect(instance.foo).to eq 123
      expect(klass.bar).to eq 456
    end
  end
end
