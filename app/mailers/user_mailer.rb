class UserMailer < ActionMailer::Base
  default from: "letshire@vmware.com"

  def interview_update(interviewer, candidate, url)
	@interviewer = interviewer
	@candidate = candidate
	@url  = url
  	mail(:to => interviewer.email, :from => Setting.find("1").mail_user, :subject => "Interview created/updated.")
  end

  def interview_delete(interviewer, candidate, url)
  	@interviewer = interviewer
	@candidate = candidate
	@url  = url
  	mail(:to => interviewer.email, :from => Setting.find("1").mail_user, :subject => "Interview deleted.")
  end
end
