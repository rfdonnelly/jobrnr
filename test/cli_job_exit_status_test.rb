# frozen_string_literal: true

require "test_helper"

describe "CLI Job Exit Status" do
  def no_color(&block)
    ENV["NO_COLOR"] = "1"
    block.call
    ENV.delete("NO_COLOR")
  end

  def assert_io_matches(exp_out, exp_err)
    out, err = capture_io do
      no_color do
        speedup do
          Kernel.stub(:trap, nil) do
            yield
          end
        end
      end
    end

    expect(out).must_match exp_out
    expect(err).must_match exp_err
  end

  it "fails" do
    exp_out = /FAILED: 'false'/
    assert_io_matches(exp_out, "") do
      Jobrnr::Application.new(%w[test/fixtures/job_exit_status/fail.rb -d fail]).run
    end
  end

  it "passes" do
    exp_out = /PASSED: 'true'/
    assert_io_matches(exp_out, "") do
      Jobrnr::Application.new(%w[test/fixtures/job_exit_status/pass.rb -d pass]).run
    end
  end

  it "passes and fails" do
    out, err = capture_subprocess_io do
      Jobrnr::Application.new(%w[test/fixtures/job_exit_status/pass_and_fail.rb -j1 -d pass_and_fail]).run
    end

    expect(out).must_match(/PASSED: 'job 0' pass_and_fail00 slot:♲ exitcode:0/)
    expect(out).must_match(/FAILED: 'job 1' pass_and_fail00 slot:0 exitcode:1/)
    expect(out).must_match(/FAILED: 'job 42' pass_and_fail01 slot:1 exitcode:42/)
    expect(err).must_equal ""
  end
end
