# Copied from jenkins cookbook helper library
begin
  open('https://localhost/whoAmI/', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
rescue SocketError,
       Errno::ECONNREFUSED,
       Errno::ECONNRESET,
       Errno::ENETUNREACH,
       Errno::EADDRNOTAVAIL,
       Timeout::Error,
       OpenURI::HTTPError => e
  # If authentication has been enabled, the server will return an HTTP
  # 403. This is "OK", since it means that the server is actually
  # ready to accept requests.
  return if e.message =~ /^403/

  puts "Jenkins is not accepting requests - #{e.message}"
  sleep(0.5)
  retry
end
