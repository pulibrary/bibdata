class AlmaAdapter
  class BibItem < SimpleDelegator
    def composite_location
      "#{library}$#{location}"
    end
  end
end
