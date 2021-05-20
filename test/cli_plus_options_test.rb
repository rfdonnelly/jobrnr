# frozen_string_literal: true

require "test_helper"

describe "CLI Plus Options" do
  def assert_io_matches(exp_out, exp_err)
    out, err = capture_io do
      speedup do
        Kernel.stub(:trap, nil) do
          yield
        end
      end
    end

    assert_equal exp_out, out
    assert_equal exp_err, err
  end

  describe "import" do
    it "defaults" do
      exp_out = Jobrnr::Util.strip_heredoc(<<-EOF)
        parent: {:name=>"parent", :child_name=>"child-name", :present=>false}
        child: {:name=>"child-name", :present=>false}
        Press '?' for help.
      EOF

      assert_io_matches(exp_out, "") do
        Jobrnr::Application.new(%w[examples/plus_options_import/index.jr]).run
      end
    end

    it "passes options on import" do
      exp_out = Jobrnr::Util.strip_heredoc(<<-EOF)
        parent: {:name=>"foo", :child_name=>"bar", :present=>true}
        child: {:name=>"bar", :present=>true}
        Press '?' for help.
      EOF

      assert_io_matches(exp_out, "") do
        Jobrnr::Application.new(%w[examples/plus_options_import/index.jr +name=foo +child-name=bar +present]).run
      end
    end
  end
end
