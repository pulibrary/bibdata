require 'rb_sys/extensiontask'

RbSys::ExtensionTask.new('bibdata_rs', Gem::Specification.new) do |ext|
  ext.lib_dir = 'lib/bibdata_rs'
end

namespace :rust do
  desc 'Cleanup old rust toolchain versions'
  task cleanup_toolchains: :environment do
    system <<~END_TOOLCHAIN_COMMAND
      for toolchain in $(rustup toolchain list | grep -v active | grep -v default); do
        rustup toolchain remove "$toolchain"
      done
    END_TOOLCHAIN_COMMAND
  end
end
