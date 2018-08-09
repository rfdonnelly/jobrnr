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
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          job ':job1' references undefined predecessor job(s) ':job0' @ file:line
        EOF
      end
    end

    it 'errors on absence of block' do
      @obj.stub :caller_source, 'file:line' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.job(:job0) }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF), e.message)
          job ':job0' definition is incomplete @ file:line

            Example:

              job :job0[, ...] do
                ...
              end
        EOF
      end
    end

    it 'errors on absence of execute command' do
      Jobrnr::Util.stub :caller_source, 'file:line' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.job(:job0) {} }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          job 'job0' is missing required 'execute' command @ file:line
        EOF
      end
    end

    describe 'job.execute command' do
      it 'requires a String or block' do
        e = assert_raises(Jobrnr::TypeError) do
          @obj.job :id do
            stub :caller_source, 'file:line' do
              execute
            end
          end
        end
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          'execute' expects a String or block @ file:line
        EOF
      end

      it 'requires a String or block, not both' do
        e = assert_raises(Jobrnr::TypeError) do
          @obj.job :id do
            stub :caller_source, 'file:line' do
              execute("true") {}
            end
          end
        end
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          'execute' expects a String or block not both @ file:line
        EOF
      end

      it 'requires a String' do
        e = assert_raises(Jobrnr::TypeError) do
          @obj.job :id do
            stub :caller_source, 'file:line' do
              execute 5
            end
          end
        end
        assert_match(/^'execute' expects a String or block but was given value of '5' of type '\w+' @ file:line$/, e.message)
      end
    end

    describe 'job.repeat command' do
      it 'requires an Integer' do
        e = assert_raises(Jobrnr::TypeError) do
          @obj.job :id do
            stub :caller_source, 'file:line' do
              repeat '5'
            end
          end
        end
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          'repeat' expects a positive Integer but was given value of '5' of type 'String' @ file:line
        EOF
      end

      it 'requires a positive Integer' do
        e = assert_raises(Jobrnr::TypeError) do
          @obj.job :id do
            stub :caller_source, 'file:line' do
              repeat(-1)
            end
          end
        end
        assert_match(/'repeat' expects a positive Integer but was given value of '-1' of type '\w+' @ file:line$/, e.message)
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



