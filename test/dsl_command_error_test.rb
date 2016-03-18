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
      @obj.job(:job0) {}
      e = assert_raises(Jobrnr::ArgumentError) { @obj.job(:job2, :job1) {} }
      assert_match(%q|job ':job2' references undefined predecessor job(s) ':job1' @ |, e.message)
    end
  end
end



