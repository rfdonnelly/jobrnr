module Jobrnr
  class Table
    def initialize(header:, rows:)
      @header = header
      @rows = rows
      @pastel = Pastel.new
    end

    def render
      data = [@header, *@rows]
      data.map! { |row| row.map! { |cell| cell.to_s } }
      widths = calculate_widths(data)
      # NOTE: Previously used the Ruby %-<width>s string format specifier but
      # it does not handle colors well so we roll our own formatting here.
      data.map do |row|
        row.zip(widths).map do |cell, width|
          pad_width = width - @pastel.strip(cell).size
          padding = " " * pad_width
          cell + padding
        end.join(" ")
      end.join("\n")
    end

    def calculate_widths(data)
      widths = data.first.map { 0 }

      data.each do |row|
        widths = row
          .map { |cell| @pastel.strip(cell).size }
          .zip(widths)
          .map { |pair| pair.max }
      end

      widths
    end
  end
end
