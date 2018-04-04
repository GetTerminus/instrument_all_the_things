require 'spec_helper'

describe "Helper Methods" do

  before do
    stub_const("ModuleWithSimilarMethods", module_with_similar_methods)
    stub_const("TestModule::TestClass", klass)
  end

  let(:module_with_similar_methods) do
    Module.new do
      def count
        "Count"
      end
    end
  end

  let(:klass) do
    Class.new do
      include ModuleWithSimilarMethods
      include InstrumentAllTheThings::HelperMethods
      include InstrumentAllTheThings::Methods

      def foo
        increment "foo"
      end
    end
  end

  let(:instance) { klass.new }

  context "class which has helper methods already defined" do
    it "increments the counter" do
      expect {
        instance.foo
      }.to change {
        get_counter('foo').total
      }.from(nil).to(1)
    end

    it "depractes the old count and jj" do
      expect(instance.preinstrumented_count).to eq("Count")
    end
  end
end
