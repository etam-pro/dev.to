module ValidRequest
  extend ActiveSupport::Concern

  def valid_request_origin?
    # This manually does what it was supposed to do on its own.
    # We were getting this issue:
    # HTTP Origin header (https://dev.to) didn't match request.base_url (http://dev.to)
    # Not sure why, but once we work it out, we can delete this method.
    # We are at least secure for now.
    return if Rails.env.test?

    if request.referer.present?
      request.referer.start_with?(ApplicationConfig["APP_PROTOCOL"].to_s + ApplicationConfig["APP_DOMAIN"].to_s)
    else
      raise InvalidAuthenticityToken, NULL_ORIGIN_MESSAGE if request.origin == "null"

      request.origin.nil? || request.origin.gsub("https", "http") == request.base_url.gsub("https", "http")
    end
  end

  def _compute_redirect_to_location(request, options) #:nodoc:
    case options
    # Yet another monkeypatch required to send proper protocol out.
    # In this case we make sure the redirect ends in the app protocol.
    # This is the same as the base Rails method except ApplicationConfig["APP_PROTOCOL"]
    # is used instead of request.protocol.
    when /\A([a-z][a-z\d\-+\.]*:|\/\/).*/i
      options
    when String
      (ApplicationConfig["APP_PROTOCOL"] || request.protocol) + request.host_with_port + options
    when Proc
      _compute_redirect_to_location request, instance_eval(&options)
    else
      url_for(options)
    end.delete("\0\r\n")
  end
end
