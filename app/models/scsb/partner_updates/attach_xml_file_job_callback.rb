module Scsb
  class PartnerUpdates
    class AttachXmlFileJobCallback
      def on_success(_status, options)
        options['xml_files'].each do |file|
          File.unlink(file)
        end
      end
    end
  end
end
