class ScsbMailer < ApplicationMailer

  def edd_email(args)
      @email = args[:emailAddress]
      @success = args[:success]
      @screen_message = args[:screenMessage]
      @message = args
      if @success == false
        destination_email = I18n.t('scsb.default_error_to')
      else
        destination_email = @email
      end
      mail(to: destination_email,
           subject: "EDD Request" )
  end

  def recall_email(args)
      @email = args[:emailAddress]
      @success = args[:success]
      @screen_message = args[:screenMessage]
      @message = args
      if @success == false
        destination_email = I18n.t('scsb.default_error_to')
      else
        destination_email = @email
      end
      mail(to: destination_email,
           subject: "Recall Request" )
  end

  def request_email(args)
      @email = args[:emailAddress]
      @success = args[:success]
      @screen_message = args[:screenMessage]
      @message = args
      if @success == false
        destination_email = I18n.t('scsb.default_error_to')
      else
        destination_email = @email
      end
      mail(to: destination_email,
           subject: "Offsite Request" )
  end

  def export_email(message)
      @message = message
      destination_email = 'lsupport@princeton.edu'
      mail(to: destination_email,
           subject: subject_line("Scsb Partner Export"))
  end

  def error_email(args)
  end
end
