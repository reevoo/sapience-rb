# frozen_string_literal: true
class Hash
  # Returns a Hash with all keys symbolized
  def deep_symbolize_keyz!
    deep_transform_keyz! { |key| key.to_sym rescue key } # rubocop:disable RescueModifier
  end
  alias deep_symbolize_keys! deep_symbolize_keyz!

  def deep_transform_keyz!(&block)
    _deep_transform_keyz_in_object!(self, &block)
  end
  alias deep_transform_keys! deep_transform_keyz!

  def _deep_transform_keyz_in_object!(object, &block)
    case object
    when Hash
      object.keys.each do |key|
        value = object.delete(key)
        object[yield(key)] = _deep_transform_keyz_in_object!(value, &block)
      end
      object
    when Array
      object.map! { |e| _deep_transform_keyz_in_object!(e, &block) }
    else
      object
    end
  end
  alias _deep_transform_keys_in_object! _deep_transform_keyz_in_object!
end
