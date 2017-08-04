class ScsbMailer < ApplicationMailer

  def error_email(args)
    @success = args[:success]
    @screen_message = args[:screenMessage]
    @message = args
    mail(to: I18n.t('scsb.default_error_to'),
         subject: I18n.t('scsb.default_error_subject'))
  end

  def edd_email(args)
    @email = args[:emailAddress]
    @success = args[:success]
    @screen_message = args[:screenMessage]
    @message = args
    destination_email = @email
    subject_line = I18n.t('scsb.edd.email_subject')
    mail(to: destination_email,
         subject: subject_line )
  end

  def recall_email(args)
    @email = args[:emailAddress]
    @success = args[:success]
    @screen_message = args[:screenMessage]
    @message = args
    destination_email = @email
    subject_line = I18n.t('scsb.recall.email_subject')
    mail(to: destination_email,
         subject: subject_line )
  end

  def request_email(args)
    @email = args[:emailAddress]
    @success = args[:success]
    @screen_message = args[:screenMessage]
    @message = args
    destination_email = @email
    subject_line = I18n.t('scsb.request.email_subject')
    mail(to: destination_email,
         subject: subject_line )
  end

  def export_email(message)
    @message = message
    destination_email = 'lsupport@princeton.edu'
    mail(to: destination_email,
         subject: subject_line("Scsb Partner Export"))
  end
end
