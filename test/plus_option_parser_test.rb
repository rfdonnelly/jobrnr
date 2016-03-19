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

  describe 'parse' do
    before do
      @specs = {
        default_true: {
          default: true,
          doc: 'An option with a default true value.',
        },
        default_inferred: {
          doc: 'An option with an inferred default value.',
        },
        fix_num: {
          default: 1,
          doc: 'A fixnum option.',
        },
        string: {
          default: 'hello world',
          doc: 'A string option.',
        },
      }
    end

    describe 'success' do
      it 'supports defaults' do
        exp = {
          default_true: true,
          default_inferred: false,
          fix_num: 1,
          string: 'hello world',
        }
        assert_equal(exp, @obj.parse(@specs, []))
      end

      it 'overrides defaults' do
        exp = {
          default_true: false,
          default_inferred: true,
          fix_num: 3,
          string: 'hi',
        }
        assert_equal(exp, @obj.parse(@specs, %w(+default-inferred +default-true=false +fix-num=3 +string=hi)))
      end

      it 'overrides previous' do
        exp = {
          default_true: true,
          default_inferred: false,
          fix_num: 5,
          string: 'hello',
        }
        act = @obj.parse(@specs, %w(
                         +default-inferred
                         +default-true=false
                         +fix-num=3
                         +string=hi
                         +default-inferred=false
                         +default-true
                         +fix-num=5
                         +string=hello
                         ))
        assert_equal(exp, act)
      end

      it 'accepts blank strings' do
        exp = {
          default_true: true,
          default_inferred: false,
          fix_num: 1,
          string: '',
        }
        act = @obj.parse(@specs, %w(
                         +string=
                         ))
        assert_equal(exp, act)
      end
    end

    describe 'errors' do
      it 'errors on unrecognized option' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.parse(@specs, %w(+does-not-exist)) }

        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          The following options are not valid options: +does-not-exist

          OPTIONS

            +default-true[=<value>]
              An option with a default true value. Default: true

            +default-inferred[=<value>]
              An option with an inferred default value. Default: false

            +fix-num=<value>
              A fixnum option. Default: 1

            +string=<value>
              A string option. Default: hello world
        EOF
      end

      it 'errors on missing Integer argument' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.parse(@specs, %w(+fix-num= +default-inferred)) }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          Could not parse '' as Integer type for the '+fix-num' option
        EOF
      end

      it 'errors on bad argument syntax' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.parse(@specs, %w(+fix-num 2)) }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          No argument given for '+fix-num' option
        EOF
      end

      it 'errors on bad Integer format' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.parse(@specs, %w(+fix-num=five)) }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          Could not parse 'five' as Integer type for the '+fix-num' option
        EOF
      end

      it 'errors on bad Boolean format' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.parse(@specs, %w(+default-true=five)) }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          Could not parse 'five' as Boolean type for the '+default-true' option
        EOF
      end
    end
  end
end
