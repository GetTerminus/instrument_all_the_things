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
        expect(InstrumentAllTheThings.transmitter).to receive(:increment)
          .with('exceptions.count', tags: ["exception_class:argument_error"])

        ExceptionHandler.register(ex)
      end
    end
  end
end
