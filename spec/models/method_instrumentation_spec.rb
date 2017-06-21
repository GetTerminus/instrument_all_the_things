require 'spec_helper'

describe "Method instumentation" do
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings::Methods

      instrument tags: ['foo:bar']
      def foo
        123
      end

      instrument tags: ->(*args) { ["magic:#{args[0]/5}"] }
      def dude(foo)
      end

      instrument tags: ->() { ["magic:mike"] }
      def hrm(foo)
      end

      instrument tags: ['foo:bar']
      def self.bar
        456
      end

      instrument tags: ->() { ["magic:mike"] }
      def self.nitch(foo)
      end

      instrument tags: ->(*args) { ["magic:#{args[0]/5}"] }
      def self.baz(num)
      end
    end
  end

  let(:instance) { klass.new }

  it 'provides basic instrumetation' do
    expect(instance.foo).to eq 123

    expect(get_counter('methods.count').total).to eq 1
  end

  it "provides basic instrumentation at the class level" do
    expect(klass.bar).to eq 456
    expect(get_counter('methods.count').total).to eq 1
  end

  context "exceptions" do
    it 'reraises instance errors' do
      expect(instance).to receive(:_foo_without_instrumentation)
        .and_raise('Hi there')

      expect{ instance.foo }.to raise_error('Hi there')
      expect(get_counter('exceptions.count').total).to eq 1
    end

    it "provides basic instrumentation at the class level" do
      expect(klass).to receive(:_bar_without_instrumentation)
        .and_raise('dude')
      expect{ klass.bar }.to raise_error('dude')
      expect(get_counter('exceptions.count').total).to eq 1
    end

  end

  context "tagging" do
    it "allows an array of tags" do
      expect {
        instance.foo
      }.to change {
        get_counter('methods.count').with_tags('foo:bar').total
      }.from(nil).to(1)
    end

    it "allows a proc to provide tags" do
      expect {
        instance.hrm(15)
      }.to change {
        get_counter('methods.count').with_tags('magic:mike').total
      }.from(nil).to(1)
    end

    it "allows a proc to provide tags" do
      expect {
        instance.dude(15)
      }.to change {
        get_counter('methods.count').with_tags('magic:3').total
      }.from(nil).to(1)
    end

    context "class based instrumentation" do
      it "allows an array of tags" do
        expect {
          klass.bar
        }.to change {
          get_counter("methods.count").with_tags('foo:bar').total
        }.from(nil).to(1)
      end

      it "allows a proc to provide tags" do
        expect {
          klass.nitch(15)
        }.to change {
          get_counter("methods.count").with_tags('magic:mike').total
        }.from(nil).to(1)
      end


      it "allows a proc to provide tags" do
        expect {
          klass.baz(15)
        }.to change {
          get_counter("methods.count").with_tags('magic:3').total
        }.from(nil).to(1)
      end
    end
  end
end
