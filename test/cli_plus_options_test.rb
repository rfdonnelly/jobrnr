require 'minitest/autorun'
require 'jobrnr'

describe Jobrnr::Util do
  def assert_subprocess_io_matches(exp_out, exp_err)
    out, err = capture_subprocess_io do
      yield
    end

    assert_match exp_out, out
    assert_match exp_err, err
  end

  def strip_heredoc(s)
    s.gsub(/^#{s.scan(/^\s*/).min_by{ |l| l.length} }/, "")
  end

  describe 'basic' do
    it 'takes defaults' do
      exp_out = <<-EOF.strip
        {:long=>false, :long_iter=>1, :quote=>"hello world"}
      EOF

      assert_subprocess_io_matches(exp_out, '') do
        system 'bin/jobrnr examples/argv/index.jr'
      end
    end

    it 'overrides defaults' do
      exp_out = <<-EOF.strip
        {:long=>true, :long_iter=>2, :quote=>"hello jobrnr"}
      EOF

      assert_subprocess_io_matches(exp_out, '') do
        system 'bin/jobrnr examples/argv/index.jr +long +long-iter=2 +quote="hello jobrnr"'
      end
    end

    it 'errors on unrecognized' do
      exp_err = strip_heredoc(<<-EOF)
      jobrnr: ERROR: The following options are not valid options: +does-not-exist

      OPTIONS

        +long=<value>
          Long regression. Default: false

        +long-iter=<value>
          Number of long job iterations. Default: 1

        +quote=<value>
          A quoted string. Default: hello world
      EOF

      assert_subprocess_io_matches('', exp_err) do
        system 'bin/jobrnr examples/argv/index.jr +does-not-exist'
      end
    end
  end
end


