require 'test_helper'

describe Jobrnr::Util::DurationParser do
  it 'parses secconds' do
    expected = 45
    actual = Jobrnr::Util::DurationParser.new('45s').duration

    assert_equal(expected, actual)
  end

  it 'parses minutes' do
    expected = 5 * 60
    actual = Jobrnr::Util::DurationParser.new('5m').duration
    
    assert_equal(expected, actual)
  end

  it 'parses hours' do
    expected = 4 * 60 * 60
    actual = Jobrnr::Util::DurationParser.new('4h').duration
    
    assert_equal(expected, actual)
  end

  it 'parses days' do
    expected = 3 * 60 * 60 * 24
    actual = Jobrnr::Util::DurationParser.new('3d').duration
    
    assert_equal(expected, actual)
  end

  it 'parses multiple units' do
    expected = 1 * 60 * 60 * 24 + 2 * 60 * 60 + 3 * 60 + 4
    actual = Jobrnr::Util::DurationParser.new('1d2h3m4s').duration

    assert_equal(expected, actual)
  end

  it 'defaults to seconds' do
    expected = 70
    actual = Jobrnr::Util::DurationParser.new('70').duration

    assert_equal(expected, actual)
  end

  it 'fails on bad input' do
    e = assert_raises(Jobrnr::ArgumentError) do
      Jobrnr::Util::DurationParser.new('bad').duration
    end

    assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
      Unable to parse duration 'bad'.  Duration must be in the form of '<number><unit>[<number><unit>[...]]'.  Examples: '1m30s', '100s'
    EOF
  end

  it 'fails on space between measure and unit' do
    e = assert_raises(Jobrnr::ArgumentError) do
      Jobrnr::Util::DurationParser.new('1 m').duration
    end

    assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
      Unable to parse duration '1 m'.  Duration must be in the form of '<number><unit>[<number><unit>[...]]'.  Examples: '1m30s', '100s'
    EOF
  end

  it 'fails on invalid unit' do
    e = assert_raises(Jobrnr::ArgumentError) do
      Jobrnr::Util::DurationParser.new('1minute').duration
    end

    assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
      Invalid unit 'minute' in duration '1minute'.  Unit must be one of 's,m,h,d'.
    EOF
  end

  it 'accepts spaces between measures' do
    expected = 1 * 60 + 30
    actual = Jobrnr::Util::DurationParser.new('1m 30s').duration

    assert_equal(expected, actual)
  end
end
