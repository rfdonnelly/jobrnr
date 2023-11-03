# frozen_string_literal: true

module Jobrnr
  # Wraps a Ruby script in a Ruby class so that multiple scripts can be
  # loaded without namespace conflicts
  class Script
    # param code [String] ruby code to evaluate
    # param graph [Jobrnr::Graph] the job graph object
    # param baseclass [Class] the class context to eval within
    # param options [Struct] the options struct
    # param plus_options [Struct] the plus options struct
    def self.eval(code:, filename:, graph:, baseclass:, options:, plus_options:)
      class_obj = Class.new(baseclass)
      obj = class_obj.new(
        graph: graph,
        options: options,
        plus_options: plus_options,
      )

      begin
        obj.instance_eval(code, filename)
      rescue ::SyntaxError => e
        raise Jobrnr::SyntaxError, e
      end

      obj
    end

    # param filename [String] filename to load
    # param graph [Jobrnr::Graph] the job graph object
    # param baseclass [Class] the class context to eval within
    # param options [Struct] the options struct
    # param plus_options [Struct] the plus options struct
    def self.load(filename:, graph:, baseclass:, options:, plus_options:)
      code = IO.read(filename)
      self.eval(
        code: code,
        filename: filename,
        graph: graph,
        baseclass: baseclass,
        options: options,
        plus_options: plus_options,
      )
    end
  end
end
