# frozen_string_literal: true

module Jobrnr
  def self.in_git?
    git_top_level = %x(git -C #{__dir__} rev-parse --show-toplevel).chomp
    gem_top_level = File.dirname(File.dirname(__dir__))

    git_top_level == gem_top_level
  end

  def self.git_describe
    %x(git -C #{__dir__} describe).chomp
  end

  def self.version
    if in_git?
      format("%<version>s (%<git_describe>s)", version: VERSION, git_describe: git_describe)
    else
      VERSION
    end
  end

  VERSION = "1.1.0"
end
