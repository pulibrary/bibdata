require 'rb_sys/extensiontask'

RbSys::ExtensionTask.new('bibdata_rs', Gem::Specification.new) do |ext|
  ext.lib_dir = 'lib/bibdata_rs'
end
