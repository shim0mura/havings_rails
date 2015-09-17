module EnumType

  def state_machine(column)
    state = self.try(column)
    return "#{column}" if state.blank?
    I18n.t('states.' + self.class.table_name + '.' + column + '.' + state)
  end

end
