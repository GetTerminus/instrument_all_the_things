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
        InstrumentAllTheThings.increment('my.counter', by: 3, tags: ['a:b', 'foo:bar'])
        InstrumentAllTheThings.increment('my.counter', by: 2, tags: ['a:b', 'foo:baz'])
      }.to change { counter_value('my.counter') }.from(0).to(5)
        .and change { counter_value('my.counter', with_tags: ['a:b']) }.from(0).to(5)
        .and change { counter_value('my.counter', with_tags: ['foo:bar']) }.from(0).to(3)
        .and change { counter_value('my.counter', with_tags: ['foo:baz']) }.from(0).to(2)
    end
  end

  describe 'decrement' do
    it do
      expect {
        InstrumentAllTheThings.decrement('my.counter')
      }.to change { counter_value('my.counter') }.from(0).to(-1)
    end

    it do
      expect {
        InstrumentAllTheThings.decrement('my.counter', by: 5)
      }.to change { counter_value('my.counter') }.from(0).to(-5)
    end

    it do
      expect {
        InstrumentAllTheThings.decrement('my.counter', by: 3, tags: ['a:b', 'foo:bar'])
        InstrumentAllTheThings.decrement('my.counter', by: 2, tags: ['a:b', 'foo:baz'])
      }.to change { counter_value('my.counter') }.from(0).to(-5)
        .and change { counter_value('my.counter', with_tags: ['a:b']) }.from(0).to(-5)
        .and change { counter_value('my.counter', with_tags: ['foo:bar']) }.from(0).to(-3)
        .and change { counter_value('my.counter', with_tags: ['foo:baz']) }.from(0).to(-2)
    end
  end

  describe 'count' do
    it do
      expect {
        InstrumentAllTheThings.count('my.counter', 1)
      }.to change { counter_value('my.counter') }.from(0).to(1)
    end

    it do
      expect {
        InstrumentAllTheThings.count('my.counter', 5)
      }.to change { counter_value('my.counter') }.from(0).to(5)
    end

    it do
      expect {
        InstrumentAllTheThings.count('my.counter', 3, tags: ['a:b', 'foo:bar'])
        InstrumentAllTheThings.count('my.counter', 2, tags: ['a:b', 'foo:baz'])
      }.to change { counter_value('my.counter') }.from(0).to(5)
        .and change { counter_value('my.counter', with_tags: ['a:b']) }.from(0).to(5)
        .and change { counter_value('my.counter', with_tags: ['foo:bar']) }.from(0).to(3)
        .and change { counter_value('my.counter', with_tags: ['foo:baz']) }.from(0).to(2)
    end
  end

  describe 'gauge' do
    it do
      expect {
        InstrumentAllTheThings.gauge('my.gauge', 1)
        InstrumentAllTheThings.gauge('my.gauge', 2)
      }.to change { gauge_value('my.gauge') }.from(nil).to(2)
    end

    it do
      expect {
        InstrumentAllTheThings.gauge('my.gauge', 3, tags: ['a:b', 'foo:bar'])
        InstrumentAllTheThings.gauge('my.gauge', 1, tags: ['a:b', 'foo:bar'])
        InstrumentAllTheThings.gauge('my.gauge', 2, tags: ['a:b', 'foo:baz'])
        InstrumentAllTheThings.gauge('my.gauge', 7, tags: ['a:b'])
      }.to change { gauge_value('my.gauge') }.to(7)
        .and change { gauge_value('my.gauge', with_tags: ['a:b']) }.to(7)
        .and change { gauge_value('my.gauge', with_tags: ['foo:bar']) }.to(1)
        .and change { gauge_value('my.gauge', with_tags: ['foo:baz']) }.to(2)
    end
  end
end
