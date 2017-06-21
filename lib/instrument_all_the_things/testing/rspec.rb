
RSpec.configure do |config|
  config.before :each do
    InstrumentAllTheThings.transmitter.reset!
  end
end
