# typed: false
require 'spec_helper'

RSpec.describe Options do
  describe '.calculate_beginning_timestamp!' do
    it 'returns a Unix timestamp for a valid date string' do
      result = Options.calculate_beginning_timestamp!('2024-01-15')
      expect(result).to eq(Date.parse('2024-01-15').to_time.to_i)
    end

    it 'raises on an invalid date string' do
      expect { Options.calculate_beginning_timestamp!('not-a-date') }.to raise_error(Date::Error)
    end
  end

  describe '.enumerate_enum_values' do
    it 'returns a comma-separated string of serialized enum values' do
      result = Options.enumerate_enum_values(Post::State)
      expect(result).to eq('private, published')
    end

    it 'raises when given a non-enum class' do
      expect { Options.enumerate_enum_values(String) }.to raise_error(RuntimeError, /does not inherit from T::Enum/)
    end
  end

  describe '.get_timestamp' do
    it 'converts a Date to a Unix timestamp' do
      date = Date.new(2024, 6, 1)
      expect(Options.get_timestamp(date)).to eq(date.to_time.to_i)
    end
  end
end
