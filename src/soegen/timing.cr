module Soegen
  class Timing
    getter start_time, end_time

    def initialize(@start_time, @end_time)
    end

    def duration
      end_time - start_time
    end
  end
end
