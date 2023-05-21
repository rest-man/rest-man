module RestMan
  class Request
    class MaybeConvertExtension < ActiveMethod::Base

      argument :ext

      def call
        unless ext =~ /\A[a-zA-Z0-9_@-]+\z/
          # Don't look up strings unless they look like they could be a file
          # extension known to mime-types.
          #
          # There currently isn't any API public way to look up extensions
          # directly out of MIME::Types, but the type_for() method only strips
          # off after a period anyway.
          return ext
        end

        types = MIME::Types.type_for(ext)
        if types.empty?
          ext
        else
          types.first.content_type
        end
      end

    end
  end
end
