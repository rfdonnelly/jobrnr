require 'test_helper'

class Jobrnr::Graph
  def clear
    @jobs = {}
  end
end

describe 'DSL command usage errors' do
  before do
    Jobrnr::Graph.instance.clear
    @obj = Jobrnr::DSL::Commands.new({}, {})
  end

  describe 'job command' do
    it 'errors on predecessor not found' do
      @obj.stub :caller_source, 'file:line' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.job(:job1, :job0) {} }
        assert_equal(%q|job ':job1' references undefined predecessor job(s) ':job0' @ file:line|, e.message)
      end
    end

    it 'errors on absence of block' do
      @obj.stub :caller_source, 'file:line' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.job(:job0) }
        exp = Jobrnr::Util.strip_heredoc(<<-EOF)
          job ':job0' definition is incomplete @ file:line

            Example:

              job :job0[, ...] do
                ...
              end
        EOF
        assert_equal(exp, e.message)
      end
    end
  end

  describe 'import command' do
    it 'requires string prefix' do
      @obj.stub :caller_source, 'file:line' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.import(5, 'fixtures/empty.jr') }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          import prefix argument must be a non-blank string @ file:line
        EOF
      end
    end

    it 'requires non-empty' do
      @obj.stub :caller_source, 'file:line' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.import(' ', 'fixtures/empty.jr') }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          import prefix argument must be a non-blank string @ file:line
        EOF
      end
    end

    it 'requires file existence' do
      @obj.stub :caller_source, 'file:line' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.import('prefix', 'invalid.jr') }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          file 'invalid.jr' not found @ file:line
        EOF
      end
    end
  end
end



