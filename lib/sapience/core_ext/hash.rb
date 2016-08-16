class Hash
  # Returns a Hash with all keys symbolized
  def deep_symbolize_keys!
    deep_transform_keys! { |key| key.to_sym rescue key } # rubocop:disable RescueModifier
  end

  def deep_transform_keys!(&block)
    _deep_transform_keys_in_object!(self, &block)
  end

  def _deep_transform_keys_in_object!(object, &block)
    case object
    when Hash
      object.keys.each do |key|
        value = object.delete(key)
        object[yield(key)] = _deep_transform_keys_in_object!(value, &block)
      end
      object
    when Array
      object.map! { |e| _deep_transform_keys_in_object!(e, &block) }
    else
      object
    end
  end
end
