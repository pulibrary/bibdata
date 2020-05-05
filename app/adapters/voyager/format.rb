module Voyager
  module Format
    def format_due_date(due_date, on_reserve)
      return if due_date.nil?
      unless due_date.to_datetime < DateTime.now-30
        if on_reserve == 'Y'
          due_date = due_date.strftime('%-m/%-d/%Y %l:%M%P')
        else
          due_date = due_date.strftime('%-m/%-d/%Y')
        end
      end
    end

    def valid_ascii(string)
      string.force_encoding("ascii").encode("UTF-8", {:invalid => :replace, :replace => ''}) unless string.nil?
    end  
  end
end   