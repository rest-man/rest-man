# v1.1.0

- Drop support for Ruby < 2.6
- Support Ruby 3.1, 3.2, JRuby-9.4
- Remove support for windows platform
- Support `write_timeout`, `ssl_timeout`, `keep_alive_timeout` option
- Support `max_retries` option
- Support `ssl_min_version` and `ssl_max_version` option
- Support `close_on_empty_response` option
- Support `local_host`, `local_port` option
- Add `AbstractRequest#sucess?`
- Move doc to seperate files
- Refactor most code with `ActiveMethod`

# 1.0.0

- Fork from rest-client and rename to rest-man
- Fix old text issues
- Setup dev with MatrixEval
- Add two Github workflow
- Drop `SSLCertificateNotVerified`