class CustomProvider < HealthMonitor::Providers::Base
  def check!
    raise 'Oh oh!'
  end
end
