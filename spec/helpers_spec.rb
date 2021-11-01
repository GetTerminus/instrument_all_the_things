require 'spec_helper'

RSpec.describe 'IATT Helpers' do
  describe '#to_tracer_tags' do
    it 'echos back simple values' do
      expect(IATT.to_tracer_tags(foo: 'bar')).to eq(foo: 'bar')
    end

    it 'provides nesting with . delimiting' do
      expect(IATT.to_tracer_tags(foo: { baz: 'nitch' })).to eq('foo.baz' => 'nitch')
    end
   
    it 'provides nesting deeply' do
      expect(IATT.to_tracer_tags(foo: { baz: {one: 'nitch' } })).to eq('foo.baz.one' => 'nitch')
    end

    it 'provides nesting for arrays' do
      expect(IATT.to_tracer_tags(foo: { baz: %w[a b c] })).to eq(
        'foo.baz.0' => 'a',
        'foo.baz.1' => 'b',
        'foo.baz.2' => 'c'
      )
    end
  end
end
