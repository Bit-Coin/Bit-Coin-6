module Configurable
  extend ActiveSupport::Concern

  included do
    has_many :configurations, as: :configurable
  end

  # company.settings => { "blah" => 6, "foo" => "bar" }
  # company.settings[:blah] => 6
  def settings
    object = self
    defaults = customs = HashWithIndifferentAccess.new
    while object

      # TODO If object != initial_object && object.class == initial_object.class
      #   skip over private settings
      # elsif object == initial_object
      #   don't skip anything
      # elsif object.class != initial_object.class
      #   skip both private and protected settings
      # else we don't know what's going on 

      # Construct a hash of default settings for this object
      tmp_defaults = HashWithIndifferentAccess.new
      object.class.default_config.each { |k,v| tmp_defaults[k] = v[1] }
      defaults = tmp_defaults.merge(defaults)

      # Same thing for custom settings
      tmp_customs = object.custom_settings
      customs = tmp_customs.merge(customs)

      # Next object up the chain
      object = object.class.inherit_from ? object.send(object.class.inherit_from) : nil
    end
    defaults.merge(customs)
  end

  # Only the custom settings hash for this object
  def custom_settings
    hash = HashWithIndifferentAccess.new
    configurations.each do |c|
      case c.data_type
      when :boolean
        value = c.value == 'true' ? true : false
      when :integer
        value = c.value.to_i
      when :string
        value = c.value
      else
        raise 'not implemented'
      end
      hash[c.key] = value # cast
    end
    hash
  end

  # Override the default settings for a single object
  #   company.set_config(:blah, 6)
  #   Team.first.set_config(:foo, 'bar')
  #   user.set_config(:oberlin, :default) <-- magic value
  def set_config(key, value)

    # TODO Currently protected and private settings are not
    # excluded from the inheritance chain, so this error would
    # only be raised if someone typoed a key.
    raise "#{key} is not a registered or inherited configuration option for #{self.class}" \
      unless self.class.default_config.keys.include?(key.to_s)

    default_value = self.class.default_config[key][1]
    value = default_value if value == :default
    config = configurations.where('key = ?', key.to_s).first
    if config
      if value == default_value # setting back to default
        config.destroy
      else
        config.update_attributes(value: value.to_s) # changing a custom setting
      end
    else
      return true if value == default_value # don't create a record for the default
      configurations.create(key: key.to_s, value: value.to_s)
    end
  end

  module ClassMethods
    @@default_config = HashWithIndifferentAccess.new
    @inherit_from = nil # or block for each class included

    def default_config # including inherited defaults 
      calling_class = klass = self
      my_defaults = @@default_config[klass.to_s.downcase.to_sym] ||
        HashWithIndifferentAccess.new
      inherited_defaults = HashWithIndifferentAccess.new

      until ancestor_class(klass) == NilClass
        ancestor_defaults = @@default_config[ancestor_class(klass).to_s.downcase.to_sym] ||
          HashWithIndifferentAccess.new
        inherited_defaults.merge!(ancestor_defaults)
        klass = ancestor_class(klass)
      end
      inherited_defaults.merge(my_defaults)
    end
    alias_method :default_settings, :default_config

    def inherit_settings_from(method_string)
      @inherit_from = method_string
    end

    def inherit_from
      @inherit_from
    end

    # args:  data_type, default_value, help_text, { scope: :public }
    # data types:  boolean, integer, string
    def set_default_config(key, *args)
      klass = self.to_s.downcase.to_sym
      @@default_config[klass] ||= {}
      @@default_config[klass][key] = args
      @@default_config[klass]
    end

    # scopes: Company.has_config(:blah, true)
    def has_config(key, value)
      klass = self == self.base_class ? self : base_class

      # If the query is for a custom configuration...
      customs = has_custom_config(key, value)   
      return customs if customs.any?

      # If the query doesn't find anything, get the inverse (which may be [])
      inverses = includes(:configurations)
        .where('configurations.key = ? and configurations.value != ?', key.to_s, value.to_s)
        .references(:configurations)

      # If there are any inverses, return the inverse of the inverse set
      if inverses.any?
        where('id not in (?)', inverses.ids)

      # Without inverse overrides, either return all or none, 
      # depending on whether this key is valid for the klass
      else
        default = klass.default_config[key] # includes inherited defaults
        if default && value == default[1]
          all # the default, which all configurables share in this case
        else
          none # a non-default value that no configurable has ('lkjfjdsfoijfld' for instance)
        end
      end
    end

    # Only return those configurables that have an override
    def has_custom_config(key, value)
      includes(:configurations)
        .where(configurations: { key: key, value: value.to_s })
    end

    # Only return those configurables that have overrides
    # that do not match the value
    def has_not_custom_config(key, value)
      might_have = includes(:configurations).where(configurations: { key: key }).pluck(:id)
      has = has_custom_config(key, value).pluck(:id)
      where('id in (?)', might_have - has)
    end

    private

    # HACK until we have a reliable way to determine a class'
    # settings parent (ancestor class)
    # This is a workaround for Company < Team
    def ancestor_class(klass=nil)
      klass ||= self
      return NilClass if klass == Company
      return Company if klass == Team
      return Team if klass == User 
      raise "Cannot determine ancestor class for #{klass.to_s}"
    end
  end
end
