# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'stat reporting' do
  describe 'increment' do
    it do
      expect {
        InstrumentAllTheThings.increment('my.counter')
      }.to change { counter_value('my.counter') }.from(0).to(1)
    end

    it do
      expect {
        InstrumentAllTheThings.increment('my.counter', by: 5)
      }.to change { counter_value('my.counter') }.from(0).to(5)
    end

    it do
      expect {
        InstrumentAllTheThings.increment( 'my.counter', by: 3, tags: ['a:b', 'foo:bar'])
        InstrumentAllTheThings.increment( 'my.counter', by: 2, tags: ['a:b', 'foo:baz'])
      }.to change { counter_value('my.counter') }.from(0).to(5)
        .and change { counter_value('my.counter', with_tags: ['a:b']) }.from(0).to(5)
        .and change { counter_value('my.counter', with_tags: ['foo:bar']) }.from(0).to(3)
        .and change { counter_value('my.counter', with_tags: ['foo:baz']) }.from(0).to(2)
    end
  end
end
