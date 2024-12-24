module Scsb
  class PartnerUpdates
    class AttachXmlFileJobCallback
      def on_success(_status, options)
        puts("In AttachXmlFileJobCallback#on_success")
        options['xml_files'].each do |file|
          puts("Would delete file: #{file}")
          # File.unlink(file)
        end
      end
    end
  end
end
