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
  end
end



