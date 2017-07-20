module Devise
  module Models
    
    # Same as original devise mixin, with the exception that emails are to be unique by company.
    
    module RippleValidatable
      # All validations used by this module.
      VALIDATIONS = [ :validates_presence_of, :validates_uniqueness_of, :validates_format_of,
                      :validates_confirmation_of, :validates_length_of ].freeze

      def self.required_fields(klass)
        []
      end

      def self.included(base)
        base.extend ClassMethods
        assert_validations_api!(base)

        base.class_eval do
          validates_presence_of   :email, if: :email_required?
          validates_uniqueness_of :email, scope: :company_id, if: :email_changed?
          validates_format_of     :email, with: email_regexp, allow_blank: true, if: :email_changed?

          validates_presence_of     :password, if: :password_required?
          validates_confirmation_of :password, if: :password_required?
          validates_length_of       :password, within: password_length, allow_blank: true
        end
      end

      def self.assert_validations_api!(base) #:nodoc:
        unavailable_validations = VALIDATIONS.select { |v| !base.respond_to?(v) }

        unless unavailable_validations.empty?
          raise "Could not use :validatable module since #{base} does not respond " <<
                "to the following methods: #{unavailable_validations.to_sentence}."
        end
      end

    protected

      # Checks whether a password is needed or not. For validations only.
      # Passwords are always required if it's a new record, or if the password
      # or confirmation are being set somewhere.
      def password_required?
        !persisted? || !password.nil? || !password_confirmation.nil?
      end

      def email_required?
        true
      end

      module ClassMethods
        Devise::Models.config(self, :email_regexp, :password_length)
      end
    end
  end
end
