module Webmate
  class JSON
    def dump(obj)
      Yajl::Encoder.encode(obj)
    end

    def parse(str)
      Yajl::Parser.parse(str)
    rescue
      raise JSON::ParserError
    end
  end
end