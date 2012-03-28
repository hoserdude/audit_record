# == Schema Information
#
# Table name: audit_records
#
#  id             :integer(4)      not null, primary key
#  user_id        :integer(4)
#  action         :string(255)
#  modifications  :text
#  remote_address :string(255)
#  auditable_type :string(255)
#  auditable_id   :integer(4)
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#

class AuditRecord < ActiveRecord::Base
  serialize :modifications
  belongs_to :user
  class << self
    def create_for(record)
      unless record.audited_attribute_changes.empty?
        create(:modifications => record.audited_attribute_changes, :auditable_type => record.class.to_s, :auditable_id => record.id)
      end
    end
    def create_for_action(record, action)
      create(:action => "#{record.class.to_s}.#{action} was called", :auditable_type => record.class.to_s, :auditable_id => record.id)
    end
  end
end
