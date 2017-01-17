require 'spec_helper'

describe InstrumentAllTheThings do
  it 'has a version number' do
    expect(InstrumentAllTheThings::VERSION).not_to be nil
  end

  describe '#normalize_class_name' do
    it "underscores names" do
      expect(InstrumentAllTheThings.normalize_class_name('FooBar')).to eq 'foo_bar'
    end

    it "adds a dash for module names" do
      expect(InstrumentAllTheThings.normalize_class_name('WhatsUp::FooBar')).to eq 'whats_up-foo_bar'
    end
  end
end
