module Periods
  class Year
    include Comparable
    attr_reader :yyyy

    def initialize(yyyy)
      @yyyy = Integer(yyyy)
    end

    def quarters
      @quarters ||= (1..4).map { |quarter| YearQuarter.new("#{@yyyy}Q#{quarter}") }
    end

    def months
      @months ||= (1..12).map { |month| YearMonth.new(@yyyy, month) }
    end

    def <=>(other)
      to_dhis2 <=> other.to_dhis2
    end

    def equal?(other)
      self.class == other.class && self == other
    end

    alias eql? equal?

    delegate :hash, to: :to_dhis2

    def year
      @yyyy
    end

    def start_date
      @start_date ||= Date.parse("#{year}-01-01")
    end

    def end_date
      @end_date ||= start_date.end_of_year
    end

    def to_dhis2
      @yyyy.to_s
    end

    alias to_s to_dhis2

    def inspect
      self.class.name + "-" + to_dhis2
    end
  end
end
