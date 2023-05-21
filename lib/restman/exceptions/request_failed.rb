module RestMan

  # The request failed with an error code not managed by the code
  class RequestFailed < ExceptionWithResponse

    def default_message
      "HTTP status code #{http_code}"
    end

    def to_s
      message
    end
  end

end
