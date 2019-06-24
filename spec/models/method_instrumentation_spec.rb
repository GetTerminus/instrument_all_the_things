# frozen_string_literal: true

require 'spec_helper'

describe 'Method instumentation' do
  before do
    stub_const('TestModule::TestClass', klass)
  end

  let(:klass) do
    Class.new do
      include InstrumentAllTheThings::Methods

      instrument tags: ['foo:bar']
      def foo
        123
      end

      instrument tags: ->(*args) { ["magic:#{args[0] / 5}"] }
      def dude(foo); end

      instrument tags: -> { ['magic:mike'] }
      def hrm(foo); end

      instrument tags: ['foo:bar']
      def self.bar
        456
      end

      instrument tags: -> { ['magic:mike'] }
      def self.nitch(foo); end

      instrument tags: ->(*args) { ["magic:#{args[0] / 5}"] }
      def self.baz(num); end
    end
  end

  let(:instance) { klass.new }

  it 'provides basic instrumetation' do
    expect(instance.foo).to eq 123

    expect(get_counter('test_module.test_class.instance.foo.count').total).to eq 1
    expect(get_counter('test_module.test_class.instance.foo.success.count').total).to eq 1
  end

  it 'provides basic instrumentation at the class level' do
    expect(klass.bar).to eq 456
    expect(get_counter('test_module.test_class.class.bar.count').total).to eq 1
    expect(get_counter('test_module.test_class.class.bar.success.count').total).to eq 1
    expect(get_timings('test_module.test_class.class.bar.timing').values.length).to eq 1
  end

  context 'with stat_prefix set' do
    around do |ex|
      InstrumentAllTheThings.config.stat_prefix = InstrumentAllTheThings.config.stat_prefix.tap do |_|
        InstrumentAllTheThings.config.stat_prefix = 'stat_prefix'
        ex.run
      end
    end

    it 'provides basic instrumentation at the class level' do
      expect(klass.bar).to eq 456
      expect(get_counter('stat_prefix.test_module.test_class.class.bar.count').total).to eq 1
      expect(get_timings('stat_prefix.test_module.test_class.class.bar.timing').values.length).to eq 1
    end
  end

  context 'renaming metric key #instrumentation_key' do
    let(:klass) do
      Class.new do
        include InstrumentAllTheThings::Methods

        instrument
        def self.base; end

        instrument
        def base; end

        instrument as: -> { '123' }
        def with_proc; end

        instrument as: 'class.with_string'
        def with_string; end

        instrument as: ->(c) { c.arg_name }
        def proc_with_argument; end

        instrument prefix: 'services'
        def self.base_with_prefix; end

        instrument prefix: 'services'
        def base_with_prefix; end

        instrument prefix: 'services', as: -> { '123' }
        def with_proc_with_prefix; end

        instrument prefix: 'services', as: 'class.with_string'
        def with_string_with_prefix; end

        instrument prefix: 'services', as: ->(c) { c.arg_name }
        def proc_with_argument_with_prefix; end

        def arg_name
          'arg_name'
        end
      end
    end

    context 'Prefixes' do
      it 'defaults to the module class name . method name' do
        expect do
          TestModule::TestClass.base_with_prefix
        end.to change {
          get_counter('services.test_module.test_class.class.base_with_prefix.count').total
        }.from(nil).to(1)
      end

      it 'defaults to the module class name . method name' do
        expect do
          instance.base_with_prefix
        end.to change {
          get_counter('services.test_module.test_class.instance.base_with_prefix.count').total
        }.from(nil).to(1)
      end

      it 'accepts a proc with no params' do
        expect do
          instance.with_proc_with_prefix
        end.to change {
          get_counter('services.123.count').total
        }.from(nil).to(1)
      end

      it 'accepts a string' do
        expect do
          instance.with_string_with_prefix
        end.to change {
          get_counter('services.class.with_string.count').total
        }.from(nil).to(1)
      end

      it 'accepts a proc with arg' do
        expect do
          instance.proc_with_argument_with_prefix
        end.to change {
          get_counter('services.arg_name.count').total
        }.from(nil).to(1)
      end
    end

    it 'defaults to the module class name . method name' do
      expect do
        TestModule::TestClass.base
      end.to change {
        get_counter('test_module.test_class.class.base.count').total
      }.from(nil).to(1)
    end

    it 'defaults to the module class name . method name' do
      expect do
        instance.base
      end.to change {
        get_counter('test_module.test_class.instance.base.count').total
      }.from(nil).to(1)
    end

    it 'accepts a proc with no params' do
      expect do
        instance.with_proc
      end.to change {
        get_counter('123.count').total
      }.from(nil).to(1)
    end

    it 'accepts a string' do
      expect do
        instance.with_string
      end.to change {
        get_counter('class.with_string.count').total
      }.from(nil).to(1)
    end

    it 'accepts a proc with arg' do
      expect do
        instance.proc_with_argument
      end.to change {
        get_counter('arg_name.count').total
      }.from(nil).to(1)
    end
  end

  context 'exceptions' do
    let(:klass) do
      Class.new do
        include InstrumentAllTheThings::Methods

        instrument as: 'foo.bar.baz'
        def foo; end

        instrument as: -> { 'error_with_proc' }
        def with_proc; end

        instrument
        def no_args; end

        instrument prefix: 'services'
        def with_prefix
          raise StandardError
        end

        instrument
        def self.no_args
          raise StandardError
        end

        instrument prefix: 'services'
        def self.with_prefix
          raise StandardError
        end
      end
    end

    describe 'counting' do
      before { allow(instance).to receive(:_no_args_without_instrumentation).and_raise 'Omg Error!' }

      it 'counts exceptions' do
        expect do
          instance.no_args
        rescue StandardError
          nil
        end.to change {
          get_counter('test_module.test_class.instance.no_args.exceptions.count').total
        }.from(nil).to(1)
      end

      it 'no longer counts success' do
        expect do
          instance.no_args
        rescue StandardError
          nil
        end.to_not change {
          get_counter('test_module.test_class.instance.no_args.success.count').total
        }.from(nil)
      end
    end

    context 'prefix' do
      it 'prefixes isntance error keys' do
        expect do
          instance.with_prefix
        rescue StandardError
          nil
        end.to change {
          get_counter('services.test_module.test_class.instance.with_prefix.exceptions.count').total
        }.from(nil).to(1)
      end

      it 'prefixes class error keys' do
        expect do
          klass.with_prefix
        rescue StandardError
          nil
        end.to change {
          get_counter('services.test_module.test_class.class.with_prefix.exceptions.count').total
        }.from(nil).to(1)
      end
    end

    it 'registers the exception with the same name' do
      allow(instance).to receive(:_foo_without_instrumentation)
        .and_raise 'Omg Error!'

      expect do
        instance.foo
      rescue StandardError
        nil
      end.to change {
        get_counter('foo.bar.baz.exceptions.count').total
      }.from(nil).to(1)
    end

    it 'registers the exception with the same name for a proc' do
      allow(instance).to receive(:_with_proc_without_instrumentation)
        .and_raise 'Omg Error!'

      expect do
        instance.with_proc
      rescue StandardError
        nil
      end.to change {
        get_counter('error_with_proc.exceptions.count').total
      }.from(nil).to(1)
    end

    it 'registers the exception with the same name for the default key' do
      allow(instance).to receive(:_no_args_without_instrumentation)
        .and_raise 'Omg Error!'

      expect do
        instance.no_args
      rescue StandardError
        nil
      end.to change {
        get_counter('test_module.test_class.instance.no_args.exceptions.count').total
      }.from(nil).to(1)
    end

    it 'registers the exception with the same name for the default key on a class method' do
      expect do
        klass.no_args
      rescue StandardError
        nil
      end.to change {
        get_counter('test_module.test_class.class.no_args.exceptions.count').total
      }.from(nil).to(1)
    end
  end

  context 'tagging' do
    it 'allows an array of tags' do
      expect do
        instance.foo
      end.to change {
        get_counter('test_module.test_class.instance.foo.count').with_tags('foo:bar').total
      }.from(nil).to(1)
    end

    it 'allows a proc to provide tags' do
      expect do
        instance.hrm(15)
      end.to change {
        get_counter('test_module.test_class.instance.hrm.count').with_tags('magic:mike').total
      }.from(nil).to(1)
    end

    it 'allows a proc to provide tags' do
      expect do
        instance.dude(15)
      end.to change {
        get_counter('test_module.test_class.instance.dude.count').with_tags('magic:3').total
      }.from(nil).to(1)
    end

    context 'class based instrumentation' do
      it 'allows an array of tags' do
        expect do
          klass.bar
        end.to change {
          get_counter('test_module.test_class.class.bar.count').with_tags('foo:bar').total
        }.from(nil).to(1)
      end

      it 'allows a proc to provide tags' do
        expect do
          klass.nitch(15)
        end.to change {
          get_counter('test_module.test_class.class.nitch.count').with_tags('magic:mike').total
        }.from(nil).to(1)
      end

      it 'allows a proc to provide tags' do
        expect do
          klass.baz(15)
        end.to change {
          get_counter('test_module.test_class.class.baz.count').with_tags('magic:3').total
        }.from(nil).to(1)
      end
    end
  end
end
