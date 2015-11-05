module Luban
  module CLI
    module CoreRefinements
      refine String do
        def camelcase
          str = dup
          str.gsub!(/(\:|\/)(.?)/){ "::#{$2.upcase}" }
          str.gsub!(/(?:_+|-+)([a-z])/){ $1.upcase }
          str.gsub!(/(\A|\s)([a-z])/){ $1 + $2.upcase }
          str
        end

        def snakecase
          gsub(/::/, ':').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
        end
      end

      refine Symbol do
        def camelcase
          to_s.camelcase
        end

        def snakecase
          to_s.snakecase
        end
      end
    end
  end
end