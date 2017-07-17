# frozen_string_literal: true
module ConfigHelper
  def force_config(options = {})
    options.each do |key, _val|
      let(key) { Sapience.config.send(key) }
    end
    before do
      options.each do |key, val|
        Sapience.config.send("#{key}=".to_sym, val)
      end
    end

    after do
      options.each do |key, _val|
        Sapience.config.send("#{key}=".to_sym, send(key))
      end
    end
  end

  def use_config(options = {})
    options.each do |key, val|
      old_val = Sapience.config.send(key)
      Sapience.config.send("#{key}=".to_sym, val)
      yield
      Sapience.config.send("#{key}=".to_sym, old_val)
    end
  end
end
