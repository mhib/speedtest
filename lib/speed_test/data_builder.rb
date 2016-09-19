module SpeedTest
  class DataBuilder
    attr_reader :entries, :hours

    def initialize(wildcard)
      @wildcard = wildcard
      @entries = []
      @hours = []
    end

    def call
      fetch_data
      build_hours
    end

    def fetch_data
      Dir.glob(@wildcard).each do |file|
        input = IO.read(file)
        next if invalid_input?(input)
        @entries << Entry.new(
          file[-24..-11],
          *REGEXPS.map { |_k, v| input.match(v).captures.first.to_f }
        )
      end
    end

    def build_hours
      @entries.group_by { |n| n.date[0..4] }.each do |k, v|
        next unless k.end_with? ':00'
        @hours << Hour.new(k, v)
      end
      @hours.sort_by!(&:hour)
    end

    private

    def invalid_input?(input)
      input.empty? or input.start_with? 'Could not' or input.start_with? 'Failed'
    end
  end
end
