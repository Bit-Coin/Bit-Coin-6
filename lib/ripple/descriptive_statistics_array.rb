module Ripple
  
  # An array with descriptive statistical magic
  
  class DescriptiveStatisticsArray < Array
    include DescriptiveStatistics
    
    def survey_statistics
      ds = descriptive_statistics
      ds.merge(hist_five(ds[:number]))
    end
    
    def hist_five(total)
      {
        :hist1 => hist_n(1, total),
        :hist2 => hist_n(2, total),
        :hist3 => hist_n(3, total),
        :hist4 => hist_n(4, total),
        :hist5 => hist_n(5, total)
      }
    end
    
    # Faster than any block/iterator method
    
    def hist_n(n, total)
      i = self.length
      count = 0
      while i > 0
        i -= 1
        count += 1 if self[i] === n
      end
      count.to_f / total
    end
  end
end

