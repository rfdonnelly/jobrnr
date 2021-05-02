# frozen_string_literal: true

require "test_helper"

describe "CLI Job Exit Status" do
  def assert_subprocess_io_matches(exp_out, exp_err)
    out, err = capture_subprocess_io do
      yield
    end

    expect(out).must_match exp_out
    expect(err).must_match exp_err
  end

  it "fails" do
    exp_out = /FAILED: 'false'/
    assert_subprocess_io_matches(exp_out, "") do
      system "bin/jobrnr test/fixtures/job_exit_status/fail.rb"
    end
  end

  it "passes" do
    exp_out = /PASSED: 'true'/
    assert_subprocess_io_matches(exp_out, "") do
      system "bin/jobrnr test/fixtures/job_exit_status/pass.rb"
    end
  end

  it "passes and fails" do
    out, err = capture_subprocess_io do
      system "bin/jobrnr test/fixtures/job_exit_status/pass_and_fail.rb"
    end

    expect(out).must_match(/PASSED: 'true'/)
    expect(out).must_match(/FAILED: 'false'/)
    expect(err).must_equal ""
  end
end
