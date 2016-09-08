class Symbol
  def camelize(uppercase_first_letter = true)
    string = self.to_s
    string = if uppercase_first_letter
               string.sub(/^[a-z\d]*/) { $&.capitalize }
             else
               string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
             end
    string.gsub!(%r{(?:_|(\/))([a-z\d]*)}i) do
      "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}"
    end
    string.gsub!(%r{/}, '::')
    string
  end #unless :sym.respond_to?(:camelize)
end