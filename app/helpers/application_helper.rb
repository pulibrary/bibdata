module ApplicationHelper
  def sanitize(str)
    str.gsub(/[^A-Za-z0-9]/, '')
  end
end
