module Soegen
  class Timing
    getter start_time : Time
    getter end_time : Time

    def initialize(@start_time, @end_time)
    end

    def duration
      end_time - start_time
    end
  end
end
