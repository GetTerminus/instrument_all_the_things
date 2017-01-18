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

  describe ".with_tags" do
    it "temporarily adds tags to the active tags" do
      InstrumentAllTheThings.active_tags.clear
      block_run = false
      InstrumentAllTheThings.with_tags('foo', 'bar') do
        block_run = true
        expect(InstrumentAllTheThings.active_tags).to include 'foo', 'bar'
      end
      expect(block_run).to eq true
      expect(InstrumentAllTheThings.active_tags).to be_empty
    end

    it "dosn't remove keys that already existed" do
      InstrumentAllTheThings.active_tags << 'hrm'

      InstrumentAllTheThings.with_tags('hrm', 'bar') do
      end

      expect(InstrumentAllTheThings.active_tags).to include 'hrm'
    end
  end
end
