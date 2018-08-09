require 'test_helper'

describe Jobrnr::PlusOptionParser do
  before do
    @obj = Jobrnr::PlusOptionParser.new
  end

  describe 'spec_to_def' do
    it 'infers String' do
      definition = @obj.spec_to_def(:string_option, {default: 'string', doc: 'description'})

      assert_instance_of(Jobrnr::PlusOptionParser::StringOption, definition)
      assert_equal('string', definition.default)

      assert_equal(:string_option, definition.id)
      assert_equal('string-option', definition.name)
      assert_equal('description', definition.description)
    end

    it 'infers Integer' do
      definition = @obj.spec_to_def(:integer_option, {default: 5, description: 'doc'})

      assert_instance_of(Jobrnr::PlusOptionParser::IntegerOption, definition)
      assert_equal(5, definition.default)
      assert_equal('doc', definition.description)
    end

    it 'infers true as Boolean' do
      definition = @obj.spec_to_def(:boolean_option, {default: true, doc: 'doc'})

      assert_instance_of(Jobrnr::PlusOptionParser::BooleanOption, definition)
      assert_equal(true, definition.default)
    end

    it 'infers false default' do
      definition = @obj.spec_to_def(:boolean_option, {})
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
          description: 'An option with an inferred default value.',
        },
        integer: {
          default: 1,
          doc: 'An integer option.',
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
          integer: 1,
          string: 'hello world',
        }
        assert_equal(exp, @obj.parse(@specs, []))
      end

      it 'overrides defaults' do
        exp = {
          default_true: false,
          default_inferred: true,
          integer: 3,
          string: 'hi',
        }
        assert_equal(exp, @obj.parse(@specs, %w(+default-inferred +default-true=false +integer=3 +string=hi)))
      end

      it 'overrides previous' do
        exp = {
          default_true: true,
          default_inferred: false,
          integer: 5,
          string: 'hello',
        }
        act = @obj.parse(@specs, %w(
                         +default-inferred
                         +default-true=false
                         +integer=3
                         +string=hi
                         +default-inferred=false
                         +default-true
                         +integer=5
                         +string=hello
                         ))
        assert_equal(exp, act)
      end

      it 'accepts blank strings' do
        exp = {
          default_true: true,
          default_inferred: false,
          integer: 1,
          string: '',
        }
        act = @obj.parse(@specs, %w(
                         +string=
                         ))
        assert_equal(exp, act)
      end

      describe '+help' do
        it 'general' do
          e = assert_raises(Jobrnr::HelpException) { @obj.parse(@specs, %w(+help)) }

          assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
            OPTIONS

              +default-true[=<value>]
                An option with a default true value. Default: true

              +default-inferred[=<value>]
                An option with an inferred default value. Default: false

              +integer=<value>
                An integer option. Default: 1

              +string=<value>
                A string option. Default: hello world

              +help
                Show this help and exit.
          EOF
        end

        it 'supports man doc' do
          e = assert_raises(Jobrnr::HelpException) do
              @obj.parse({
                  name: 'file',
                  synopsis: 'jobrnr file.jr',
                  description: "line1\nline2",
                  options: @specs,
                  extra: Jobrnr::Util.strip_heredoc(<<-EOF).strip
                    EXAMPLES

                      blah
                  EOF
              }, %w(+help))
          end

          assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
            NAME

              file

            SYNOPSIS

              jobrnr file.jr

            DESCRIPTION

              line1
              line2

            OPTIONS

              +default-true[=<value>]
                An option with a default true value. Default: true

              +default-inferred[=<value>]
                An option with an inferred default value. Default: false

              +integer=<value>
                An integer option. Default: 1

              +string=<value>
                A string option. Default: hello world

              +help
                Show this help and exit.

            EXAMPLES

              blah
          EOF
        end
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

            +integer=<value>
              An integer option. Default: 1

            +string=<value>
              A string option. Default: hello world

            +help
              Show this help and exit.
        EOF
      end

      it 'errors on missing Integer argument' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.parse(@specs, %w(+integer= +default-inferred)) }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          Could not parse '' as Integer type for the '+integer' option
        EOF
      end

      it 'errors on bad argument syntax' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.parse(@specs, %w(+integer 2)) }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          No argument given for '+integer' option
        EOF
      end

      it 'errors on bad Integer format' do
        e = assert_raises(Jobrnr::ArgumentError) { @obj.parse(@specs, %w(+integer=five)) }
        assert_equal(Jobrnr::Util.strip_heredoc(<<-EOF).strip, e.message)
          Could not parse 'five' as Integer type for the '+integer' option
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
