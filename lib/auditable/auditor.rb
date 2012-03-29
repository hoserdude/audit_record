require "#{File.dirname(__FILE__)}/audit_record"
module Auditable
  module Auditor
    def self.included(base)
      base.module_eval do
        attr_accessor :audited_attribute_changes
      end
      base.extend ClassMethods
    end
    module ClassMethods
      def audit(opts = {})
        options = HashWithIndifferentAccess.new({ :attributes => [], :methods => [] }).merge(opts)
        add_auditable_actions(options[:methods])
        add_auditable_attributes(options[:attributes])
        has_many :audit_records, :as => :auditable

        include Auditor::InstanceMethods
      end

      def audited_attributes
        if self.base_class == self
          Array(@audited_attributes)
        else
          self.base_class.audited_attributes if @audited_attributes.nil?
        end
      end
      private
      def add_auditable_attributes(optional_attributes)
        @audited_attributes = []
        [optional_attributes].flatten.each { |attribute| @audited_attributes << attribute.to_sym }
        unless @audited_attributes.empty?
          after_save :audit_changes
        end
      end

      def add_auditable_actions(optional_actions)
        [optional_actions].flatten.each do |a|
          ending = ''
          action = a.to_s
          if ['!','?'].any?{ |x| action.last == x }
            ending = action.slice!(/(.)$/)
          end
          send :define_method, "#{action}_with_action_audit#{ending}".to_sym do
            AuditRecord.create_for_action(self, a)
            self.send("#{action}_without_action_audit#{ending}")
          end
          alias_method_chain a, :action_audit
        end
      end
    end
    module InstanceMethods

      private
      def audit_changes(*args)

        self.audited_attribute_changes = changes.dup

        # Delete keys we don't want to moderate anyway.
        self.audited_attribute_changes.delete_if{ |k,v| [:id, :updated_at, :created_at].include?(k.to_sym) }

        # Delete changes that were nil but are now blank.
        # This is useful for when optional fields of new records are saved wtih no content.
        self.audited_attribute_changes.delete_if{ |k,v| v == [nil,'']}

        # If no attributes are supplied then the entire record is moderated otherwise moderate only the supplied columns.
        unless self.class.base_class.audited_attributes.empty?
          self.audited_attribute_changes.delete_if{ |k,v| !self.class.base_class.audited_attributes.include?(k.to_sym) }
        end
        AuditRecord.create_for(self)
      end
    end
  end

  if defined?(ActiveRecord) and defined?(ActiveRecord::Base)
    ActiveRecord::Base.class_eval { include Auditable::Auditor }
  end

  if defined?(ActionController) and defined?(ActionController::Base)
    require "#{File.dirname(__FILE__)}/audit_record_sweeper"
    ActionController::Base.class_eval do
      cache_sweeper :audit_record_sweeper
    end
  end
end