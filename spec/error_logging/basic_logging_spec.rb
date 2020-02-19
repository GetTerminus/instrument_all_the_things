RSpec.describe 'error logging on instance methods' do
  let(:error_logging_options) { {} }
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings

      instrument error_logging: true
      def bar
        foo
      end

      def self.to_s
        'KlassName'
      end
    end
  end

  let(:instance) { klass.new }
  subject(:call_error_logged_method) { instance.foo }

  before do
    klass.instrument(error_logging: error_logging_options)
    klass.define_method(:foo) { |*i| raise 'Foobar' }
  end

  it 'logs the error to the IATT logger' do
    expect(IATT.logger).to receive(:error).with('An error occurred in KlassName.foo')
    expect(IATT.logger).to receive(:error).with('Foobar')
    expect(IATT.logger).to receive(:error).with(/.*\.rb/).at_least(1).times

    call_error_logged_method rescue nil
  end

  it 're-raises the exception' do
    expect(IATT.logger).to receive(:error).at_least(1).times
    expect { call_error_logged_method }.to raise_error('Foobar')
  end

  it 'only logs the error once' do
    expect(IATT.logger).not_to receive(:error).with('An error occurred in KlassName.bar')
    expect(IATT.logger).to receive(:error).at_least(1).times

    instance.bar rescue nil
  end
end
