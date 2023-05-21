module RestMan

  # The server broke the connection prior to the request completing.  Usually
  # this means it crashed, or sometimes that your network connection was
  # severed before it could complete.
  class ServerBrokeConnection < RestMan::Exception
    def initialize(message = 'Server broke connection')
      super nil, nil
      self.message = message
    end
  end

end
