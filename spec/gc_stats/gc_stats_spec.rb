# frozen_string_literal: true

RSpec.describe 'error logging on instance methods' do
  let(:gc_stats_options) { {} }
  let(:first_gc_stats) do
    {
      total_allocated_pages: 10,
      total_allocated_objects: 100,
      count: 10,
    }
  end

  let(:second_gc_stats) do
    {
      total_allocated_pages: 11,
      total_allocated_objects: 90,
      count: 13,
    }
  end

  let(:klass) do
    Class.new do
      include InstrumentAllTheThings

      def self.to_s
        'KlassName'
      end
    end
  end

  let(:instance) { klass.new }
  subject(:call_gc_stats_method) { instance.foo }

  before do
    allow(
      InstrumentAllTheThings::Instrumentors::GC_STAT_GETTER,
    ).to receive(:call).and_return(first_gc_stats, second_gc_stats)

    klass.instrument(gc_stats: gc_stats_options)
    klass.define_method(:foo) { |*_i| 123 }
  end

  it 'returns the function value' do
    expect(call_gc_stats_method).to eq 123
  end

  it do
    expect {
      call_gc_stats_method
    }.to change {
      histogram_value('KlassName.instance_methods.foo.total_allocated_pages_change')
    }.by(1)
      .and change {
             histogram_value('KlassName.instance_methods.foo.total_allocated_objects_change')
           }.by(-10)
      .and change {
             histogram_value('KlassName.instance_methods.foo.count_change')
           }.by(3)
  end
end
