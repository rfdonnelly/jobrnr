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
      fmtstrs = widths.map { |width| "%-#{width}s" }
      fmtstr = fmtstrs.join(" ")
      data.map { |row| format(fmtstr, *row) }.join("\n")
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
