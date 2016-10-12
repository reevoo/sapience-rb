module Sapience
  module Extensions
    module Grape
      module RequestFormatHelper
        def request_format(env)
          content_type = env["CONTENT_TYPE"] || env["CONTENT-TYPE"]
          content_type.to_s.split("/").last
        end
      end
    end
  end
end
