module ApplicationHelper
  def sanitize(str)
    str.gsub(/[^A-Za-z0-9.]/, '')
  end

  def sanitize_array(arr)
    arr.map { |s| sanitize(s) }
  end
end
