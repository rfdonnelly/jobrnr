require 'test_helper'

describe 'CLI Plus Options' do
  def assert_subprocess_io_matches(exp_out, exp_err)
    out, err = capture_subprocess_io do
      yield
    end

    assert_equal exp_out, out
    assert_equal exp_err, err
  end

  describe 'import' do
    it 'defaults' do
      exp_out = Jobrnr::Util.strip_heredoc(<<-EOF)
        parent: {:name=>"parent", :child_name=>"child-name", :present=>false}
        child: {:name=>"child-name", :present=>false}
      EOF

      assert_subprocess_io_matches(exp_out, '') do
        system 'bin/jobrnr examples/plus_options_import/index.jr'
      end
    end

    it 'passes options on import' do
      exp_out = Jobrnr::Util.strip_heredoc(<<-EOF)
        parent: {:name=>"foo", :child_name=>"bar", :present=>true}
        child: {:name=>"bar", :present=>true}
      EOF

      assert_subprocess_io_matches(exp_out, '') do
        system 'bin/jobrnr examples/plus_options_import/index.jr +name=foo +child-name=bar +present'
      end
    end
  end
end
