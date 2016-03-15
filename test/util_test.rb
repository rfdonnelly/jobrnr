require 'test_helper'

describe Jobrnr::Util do
  before do
    @obj = Jobrnr::Util
  end

  describe 'array_subset_of?' do
    describe 'ordered arrays' do
      a = [0, 1, 2, 3]
      b = [0, 1, 2, 3, 4]

      it 'returns true for a in b' do
        assert(@obj.array_subset_of?(a, b))
      end

      it 'returns false for b in a' do
        assert(!@obj.array_subset_of?(b, a))
      end
    end

    describe 'unordered arrays' do
      a = [3, 1, 2, 0]
      b = [5, 2, 3, 1, 0]

      it 'returns true for a in b' do
        assert(@obj.array_subset_of?(a, b))
      end

      it 'returns false for b in a' do
        assert(!@obj.array_subset_of?(b, a))
      end
    end

    describe 'duplicate entries' do
      a = [1, 2, 3]
      b = [1, 1, 2, 3]

      it 'returns true for a in b' do
        assert(@obj.array_subset_of?(a, b))
      end

      it 'returns false for b in a' do
        assert(!@obj.array_subset_of?(b, a))
      end
    end
  end

  describe 'expand_envars' do
    before do
      ENV['ENVAR0'] = 'asdf'
      ENV['ENVAR1'] = 'hjkl'
    end

    it 'expands non-bracketed envars' do
      assert_equal('asdf/hjkl', @obj.expand_envars('$ENVAR0/hjkl'))
    end

    it 'expands bracketed envars' do
      assert_equal('asdf/hjkl', @obj.expand_envars('${ENVAR0}/hjkl'))
    end

    it 'expands multiple envars' do
      assert_equal('asdf/hjkl', @obj.expand_envars('${ENVAR0}/$ENVAR1'))
    end

    it 'expands undefined envars as blank' do
      assert_equal('/hjkl', @obj.expand_envars('$LKRJELA/hjkl'))
    end
  end

  describe 'relative_to_file' do
    it 'makes from_file relative to to_file' do
      from = 'path_a/file_a'
      to = 'path_b/file_b'
      exp = File.join(Dir.pwd, 'path_b/path_a/file_a')

      assert_equal(exp, @obj.relative_to_file(from, to))
    end
  end
end
