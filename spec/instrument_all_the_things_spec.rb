require 'pry'

class Foo
  include IATT::Helpers

  def initialize(x)
    @x = x
  end

  instrument
  def foo
    puts 'b'
  end

  instrument
  def bar
    puts 'b'
  end
end

RSpec.describe InstrumentAllTheThings do
  it "has a version number" do
    expect(InstrumentAllTheThings::VERSION).not_to be nil
  end

  it "does something useful" do
    x = Foo.new(123)
    x.bar
    expect(false).to eq(true)
  end
end
