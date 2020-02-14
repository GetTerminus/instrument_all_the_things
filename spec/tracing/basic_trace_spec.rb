# frozen_string_literal: true

require 'spec_helper'
require 'pry'

RSpec.describe 'basic trace' do
  let(:klass) do
    Class.new do
      include InstrumentAllTheThings

      instrument
      def foo; end
    end
  end

  it 'creates a trace' do
    expect { klass.new.foo }.to change {
      emitted_spans(
        filtered_by: { name: 'method.execution' }
      ).length
    }.by(1)
  end
end
