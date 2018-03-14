require 'spec_helper'


module ModuleWithAliasedMethods
  def count
    "Count"
  end
end

class DupMethodClass
  include ModuleWithAliasedMethods
  include InstrumentAllTheThings::HelperMethods
  include InstrumentAllTheThings::Methods 

  def foo
    increment "foo"
  end  
end

describe "Helper Methods" do
  
  # before do
  #   stub_const("ModuleWithSimilarMethods", module_with_similar_methods)
  #   stub_const("TestModule::TestClass", klass)
  # end

  # let(:klass) do
  #   Class.new do
  #     include ModuleWithSimilarMethods
  #     include InstrumentAllTheThings::HelperMethods
  #     include InstrumentAllTheThings::Methods    

  #     def foo
  #       increment "foo"
  #     end  
  #   end
  # end

  let(:klass) { DupMethodClass }

  let(:instance) { klass.new }

  context "class which has helper methods already defined" do
    # let(:module_with_similar_methods) do
    #   Module.new do
    #     def count
    #       "Count"
    #     end
    #   end
    # end

    it "increments the counter" do
      expect {
        instance.foo
      }.to change {
        get_counter('foo').total
      }.from(nil).to(1)
    end

    it "doesn't override helper methods when they're already defined" do
      expect { instance.count }.not_to raise_error(ArgumentError)
      expect(instance.count).to eq("Count")
    end
  end
end
