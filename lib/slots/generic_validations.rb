# frozen_string_literal: true

module GenericValidations
  extend ActiveSupport::Concern

  included do
    validate :unique_and_present, :logins_meets_criteria
  end

  def logins_meets_criteria
    return if self.errors.any?
    return unless Slots.configuration.login_regex_validations
    logins = Slots.configuration.logins
    login_c = logins.keys
    logins.each do |col, reg|
      login_c.delete(col) # Login columns left
      column_match(reg, col)
      column_dont_match(reg, col, login_c)
    end
  end

  def unique_and_present
    # Use this rather than validates because logins in configure might not be set yet on include
    Slots.configuration.logins.each do |column, _|
      value = self.send(column)
      self.errors.add(column, "can't be blank") unless value.present?
      pk_value = self.send(self.class.primary_key)
      self.errors.add(column, "already taken") if self.class.where.not(self.class.primary_key => pk_value).exists?(column => value)
    end
  end

  def column_match(regex, column)
    # TODO change error message to use locals? or something configurable
    self.errors.add(column, "didn't match login criteria") unless self.send(column).match(regex)
  end

  def column_dont_match(regex, column_not_to_match, columns)
    columns.each do |c|
      # Since we check if any errors should be present
      self.errors.add(c, "matched #{column_not_to_match} login criteria") if self.send(c).match(regex)
    end
  end

  module ClassMethods
  end
end