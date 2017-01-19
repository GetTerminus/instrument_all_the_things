require 'spec_helper'

module InstrumentAllTheThings
  describe ControllerAction do
    let(:current_request) { ControllerAction.request }

    describe ".begin_rails_action" do
      let(:event_payload) do
        {
          controller: 'Foo',
          action: 'new',
          format: 'all',
          params: {},
          headers: {},
          method: 'GET',
          path: ''
        }
      end

      it "converts nil format to all" do
        event_payload.delete :format
        expect(ControllerAction).to receive(:begin_request).with(a_hash_including(format: 'all')).once
        ControllerAction.begin_rails_action(double(payload: event_payload))
      end

      it "converts */* format to all" do
        event_payload[:format] = '*/*'
        expect(ControllerAction).to receive(:begin_request).with(a_hash_including(format: 'all')).once
        ControllerAction.begin_rails_action(double(payload: event_payload))
      end

      it "transmits all keys" do
        expect(ControllerAction).to receive(:begin_request).with(a_hash_including(controller: 'Foo', action: 'new', method: 'GET', format: 'all')).once
        ControllerAction.begin_rails_action(double(payload: event_payload))
      end
    end

    describe ".begin_request" do
      let(:options) do
        {
          controller: 'OmgController',
          action: 'foo',
          format: 'all',
          method: 'GET',
        }
      end

      let(:begin_request) { ControllerAction.begin_request(options) }

      it "dosn't create a new request object" do
        expect{ begin_request }.not_to change{ ControllerAction.request.object_id }
      end

      it "calls reset on the request object" do
        expect(ControllerAction.request).to receive(:reset!)
        begin_request
      end

      it "updates the request with the passed values" do
        begin_request
        expect(current_request).to have_attributes options.merge(controller: 'omg_controller')
      end
    end

    describe ".complete_request" do
      let(:options) do
        {
          status: 200,
          runtimes: {db_runtime: 100, view_runtime: 100}
        }
      end
      before do
        ControllerAction.begin_request controller: 'DudeController', action: 'foo', format: 'all', method: 'get'
      end

      subject(:complete_action) { ControllerAction.complete_request(options) }

      it "updates the current request" do
        allow(current_request).to receive(:reset!).and_return(true)
        complete_action
        expect(current_request).to have_attributes options
      end
    end

  end
end
