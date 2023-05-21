module RestMan

  STATUSES_COMPATIBILITY = {
    # The RFCs all specify "Not Found", but "Resource Not Found" was used in
    # earlier RestMan releases.
    404 => ['ResourceNotFound'],

    # HTTP 413 was renamed to "Payload Too Large" in RFC7231.
    413 => ['RequestEntityTooLarge'],

    # HTTP 414 was renamed to "URI Too Long" in RFC7231.
    414 => ['RequestURITooLong'],

    # HTTP 416 was renamed to "Range Not Satisfiable" in RFC7233.
    416 => ['RequestedRangeNotSatisfiable'],
  }

end