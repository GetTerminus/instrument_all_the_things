require 'spec_helper'

module InstrumentAllTheThings
  RSpec.describe BackendJob do
    describe '.tags_for_job' do
      let(:faux_job) { stub_const("Omg::FooBarBaz", Class.new { }) }
      let(:job_instance) { faux_job.new }

      it "adds a job for the backend class" do
        expect(
          BackendJob.tags_for_job(job_instance, faux_job)
        ).to match_array [
          "backend_job_class:omg-foo_bar_baz",
          "backend_job_queue:UNKNOWN"
        ]
      end

      context ".start" do
        it "returns the block value" do
          expect(
            BackendJob.start(job: 1){ 1234 }
          ).to eq 1234
        end
      end

      context "when there is a queue attribute set on the job" do
        let(:faux_job) do
          stub_const("Omg::FooBarBaz", Class.new { attr_accessor :queue })
        end

        it "sets the queue to unknown if it is null" do
          expect(
            BackendJob.tags_for_job(job_instance, faux_job)
          ).to include "backend_job_queue:UNKNOWN"
        end

        it "sets the queue to unknown if it is a blank string" do
          job_instance.queue = ''
          expect(
            BackendJob.tags_for_job(job_instance, faux_job)
          ).to include "backend_job_queue:UNKNOWN"
        end

        it "sets the queue to the queue name if it is set" do
          job_instance.queue = 'OmgWTF'
          expect(
            BackendJob.tags_for_job(job_instance, faux_job)
          ).to include "backend_job_queue:OmgWTF"
        end
      end
    end
  end
end
