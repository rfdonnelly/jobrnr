require 'test_helper'

describe Jobrnr::PlusOptionParser do
  before do
    @obj = Jobrnr::PlusOptionParser.new
  end

  describe 'transform_spec' do
    it 'infers String' do
      definition = @obj.transform_spec(:string_option, {default: 'string', doc: 'doc'})

      assert_instance_of(Jobrnr::PlusOptionParser::StringOption, definition)
      assert_equal('string', definition.default)

      assert_equal(:string_option, definition.id)
      assert_equal('string-option', definition.name)
      assert_equal('doc', definition.doc)
    end

    it 'infers FixNum' do
      definition = @obj.transform_spec(:fixnum_option, {default: 5, doc: 'doc'})

      assert_instance_of(Jobrnr::PlusOptionParser::FixnumOption, definition)
      assert_equal(5, definition.default)
    end

    it 'infers true as Boolean' do
      definition = @obj.transform_spec(:boolean_option, {default: true, doc: 'doc'})

      assert_instance_of(Jobrnr::PlusOptionParser::BooleanOption, definition)
      assert_equal(true, definition.default)
    end

    it 'infers false default' do
      definition = @obj.transform_spec(:boolean_option, {})
      assert_instance_of(Jobrnr::PlusOptionParser::BooleanOption, definition)
      assert_equal(false, definition.default)
    end
  end
end
