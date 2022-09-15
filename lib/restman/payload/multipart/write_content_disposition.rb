module RestMan
  module Payload
    class Multipart
      class WriteContentDisposition < ActiveMethod::Base

        argument :stream
        argument :name
        argument :value
        argument :boundary

        def call
          if file?
            write_header_for_file_field
          else
            write_header_for_regular_field
          end
        end

        private

        def file?
          value.respond_to?(:read) && value.respond_to?(:path)
        end

        def write_header_for_regular_field
          write "--#{boundary}\r\n"
          write "Content-Disposition: form-data;#{name_directive}\r\n"
          write "\r\n"
          write "#{value}\r\n"
        end

        def write_header_for_file_field
          write "--#{boundary}\r\n"
          write "Content-Disposition: form-data;#{name_directive(";")}#{filename_directive}\r\n"
          write "Content-Type: #{content_type}\r\n"
          write "\r\n"
          while data = file.read(8124)
            write data
          end
          write "\r\n"
        ensure
          file.close if file.respond_to?(:close)
        end

        def name_directive(separator = nil)
          return if name.nil?
          return if name == ''

          %Q( name="#{name}"#{separator})
        end

        def filename_directive
          if file.respond_to?(:original_filename)
            %Q( filename="#{file.original_filename}")
          else
            %Q( filename="#{File.basename(file.path)}")
          end
        end

        def content_type
          if file.respond_to?(:content_type)
            file.content_type
          else
            mime_for file.path
          end
        end

        def mime_for(path)
          mime = MIME::Types.type_for path
          if mime.empty?
            'text/plain'
          else
            mime[0].content_type
          end
        end

        def write(str)
          stream.write str
        end

        def file
          value
        end

      end
    end
  end
end
