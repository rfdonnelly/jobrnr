require 'test_helper'

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
    describe 'success' do
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
          system 'bin/jobrnr examples/argv/index.jr +long +long-iter=2 +quote="hello jobrnr" --max-jobs 2'
        end
      end

      it 'overrides previous' do
        exp_out = <<-EOF.strip
          {:long=>false, :long_iter=>3, :quote=>"yo"}
        EOF

        assert_subprocess_io_matches(exp_out, '') do
          system 'bin/jobrnr examples/argv/index.jr +long +long-iter=2 +quote="hello jobrnr" --max-jobs 2 +long=false +long-iter=3 +quote=yo'
        end
      end

      it 'accepts blank strings' do
        exp_out = <<-EOF.strip
          {:long=>false, :long_iter=>1, :quote=>""}
        EOF

        assert_subprocess_io_matches(exp_out, '') do
          system 'bin/jobrnr examples/argv/index.jr +quote='
        end
      end
    end

    describe 'errors' do
      it 'errors on unrecognized option' do
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

      it 'errors on missing Integer argument' do
        exp_err = strip_heredoc(<<-EOF)
          jobrnr: ERROR: Could not parse '' as Integer type for the '+long-iter' option
        EOF

        assert_subprocess_io_matches('', exp_err) do
          system 'bin/jobrnr examples/argv/index.jr +long-iter= +long'
        end
      end

      it 'errors on bad argument syntax' do
        exp_err = strip_heredoc(<<-EOF)
          jobrnr: ERROR: No argument given for '+long-iter' option
        EOF

        assert_subprocess_io_matches('', exp_err) do
          system 'bin/jobrnr examples/argv/index.jr +long-iter 2'
        end
      end

      it 'errors on bad Integer format' do
        exp_err = strip_heredoc(<<-EOF)
          jobrnr: ERROR: Could not parse 'five' as Integer type for the '+long-iter' option
        EOF

        assert_subprocess_io_matches('', exp_err) do
          system 'bin/jobrnr examples/argv/index.jr +long-iter=five'
        end
      end

      it 'errors on bad Boolean format' do
        exp_err = strip_heredoc(<<-EOF)
          jobrnr: ERROR: Could not parse 'five' as Boolean type for the '+long' option
        EOF

        assert_subprocess_io_matches('', exp_err) do
          system 'bin/jobrnr examples/argv/index.jr +long=five'
        end
      end
    end
  end

  describe 'import' do
    it 'defaults' do
      exp_out = strip_heredoc(<<-EOF)
        parent: {:name=>"parent", :child_name=>"child-name", :present=>false}
        child: {:name=>"child-name", :present=>false}
      EOF

      assert_subprocess_io_matches(exp_out, '') do
        system 'bin/jobrnr examples/argv_import/index.jr'
      end
    end

    it 'passes options on import' do
      exp_out = strip_heredoc(<<-EOF)
        parent: {:name=>"foo", :child_name=>"bar", :present=>true}
        child: {:name=>"bar", :present=>true}
      EOF

      assert_subprocess_io_matches(exp_out, '') do
        system 'bin/jobrnr examples/argv_import/index.jr +name=foo +child-name=bar +present'
      end
    end
  end
end
