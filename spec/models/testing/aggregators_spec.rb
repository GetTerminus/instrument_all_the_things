require 'spec_helper'

module InstrumentAllTheThings
  module Testing
    RSpec.describe Aggregators::BaseAggregator do
      let(:instance) { described_class.new(metrics) }

      let(:value1) { {value: 1, tags: ['foo:bar', 'wassup:hrm']} }
      let(:value2) { {value: 2, tags: ['foo:baz']} }
      let(:value3) { {value: 3, tags: ['hrm:hrm']} }
      let(:value4) { {value: 4, tags: []} }

      let(:metrics) { [value1, value2, value3, value4] }

      describe "values" do
        it "returns all the change values" do
          expect(instance.values).to match_array [1, 2, 3, 4]
        end
      end

      describe "#total" do
        it "sums all the values in the metrics array" do
          expect(instance.total).to eq 10
        end
      end

      describe "#with_tags" do
        it "filters tags based on a string" do
          expect(
            instance.with_tags('foo:bar').metrics
          ).to eq [value1]
        end

        it "filters tags based on a regex" do
          expect(
            instance.with_tags(/\Afoo:/).metrics
          ).to eq [value1, value2]
        end

        it "must match all entries" do
          expect(
            instance.with_tags(/\Afoo:/, 'wassup:hrm').metrics
          ).to eq [value1]
        end
      end
    end
  end
end

