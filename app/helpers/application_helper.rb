module ApplicationHelper
  def bootstrap_class_for(flash_type)
    case flash_type
    when 'success'
      'alert-success'   # Green
    when 'error'
      'alert-danger'    # Red
    when 'alert'
      'alert-warning'   # Yellow
    when 'notice'
      'alert-info'      # Blue
    else
      flash_type.to_s
    end
  end

  def sanitize(str)
    str.gsub(/[^A-Za-z0-9.]/, '')
  end

  def sanitize_array(arr)
    arr.map { |s| sanitize(s) }
  end
end
