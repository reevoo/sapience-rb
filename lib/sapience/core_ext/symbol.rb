class Symbol
  unless :sym.respond_to?(:camelize)
    def camelize(uppercase_first_letter = true)
      string = to_s
      string = if uppercase_first_letter
                 string.sub(/^[a-z\d]*/) { $&.capitalize }
               else
                 string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
               end
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) do
        "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}"
      end
      string.gsub!(/\//, "::")
      string
    end
  end
end
