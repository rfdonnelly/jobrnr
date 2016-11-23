require 'test_helper'

describe Jobrnr::Util::TimeParser do
  it 'parses euro date' do
    expected = '2016-11-22 00:00:00 +0000'
    actual = Jobrnr::Util::TimeParser.new('2016-11-22').time.to_s

    assert_equal(expected, actual)
  end

  it 'returns a duration' do
    obj = Jobrnr::Util::TimeParser.new('2016-11-23')
    # Stub the now method
    def obj.now
      Time.local(2016, 11, 22)
    end

    expected = 24 * 60 * 60
    actual = obj.duration

    assert_equal(expected, actual)
  end

  it 'parses euro date time' do
    expected = '2016-11-22 01:02:03 +0000'
    actual = Jobrnr::Util::TimeParser.new('2016-11-22T01:02:03').time.to_s

    assert_equal(expected, actual)
  end

  it 'fails on bad input' do
    e = assert_raises(Jobrnr::ArgumentError) do
      Jobrnr::Util::TimeParser.new('bad').duration
    end

    assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
      Unable to parse time 'bad'
    EOF
  end
end
