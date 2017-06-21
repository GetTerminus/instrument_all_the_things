require 'spec_helper'

module InstrumentAllTheThings
  describe ExceptionHandler do

    describe ".register" do
      let(:ex) { ArgumentError.new }

      it "returns the exception" do
        expect(ExceptionHandler.register(ex)).to eq(ex)
      end

      it "marks the exception as reported" do
        ret_ex = ExceptionHandler.register(ex)
        expect(ret_ex._instrument_all_the_things_reported).to eq true
      end

      it "increments exceptions.count" do
        expect {
          ExceptionHandler.register(ex)
        }.to change {
          get_counter('exceptions.count')
            .with_tags("exception_class:argument_error").total
        }.from(nil).to(1)
      end

      it "allows a custom name to be sent" do
        expect {
          ExceptionHandler.register(ex, as: 'foo.bar')
        }.to change {
          get_counter('exceptions.count')
            .with_tags("exception_class:argument_error").total
        }.from(nil).to(1)
        .and change {
          get_counter('foo.bar.exceptions.count')
            .with_tags("exception_class:argument_error").total
        }.from(nil).to(1)
      end
    end
  end
end
