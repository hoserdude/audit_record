class AuditRecordSweeper < ActionController::Caching::Sweeper
  observe AuditRecord
  def before_create(audit_record)
    audit_record.user_id ||= current_user.id unless current_user.nil?
    audit_record.remote_address = controller.try(:request).try(:ip)
  end
end