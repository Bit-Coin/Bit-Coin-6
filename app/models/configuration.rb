class Configuration < ActiveRecord::Base
  belongs_to :configurable, polymorphic: true
  rails_admin do
    list do
      field :id
      field :created_at
      field :updated_at
      field :configurable_id
      field :configurable_type
    end
  end

  # Configs and their default values are defined
  # in the Conifgurables themselves.  See the
  # Configurable concern for more doco.

  # The only time you need a relation is if you
  # are overriding the default.  All that is
  # handled by Configurable#set_config

  # Look in settings hash for data type
  # :boolean, :integer, :string
  def data_type(klass=nil)
    klass ||= configurable.class
    setting = klass.default_settings[key]

    # HACK to work around Company < Team issue
    unless setting
      setting = Company.default_settings[key]
    end

    # Climb the inheritance tree
    until klass == NilClass || setting
      klass = configurable.send(klass.inherit_from).class
      setting = klass.default_settings[key]
    end

    setting[0]
  end
end
