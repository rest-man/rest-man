require 'spec_helper'

describe RestMan::Exceptions::EXCEPTIONS_MAP do

   it 'can success map for 1xx code' do
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[100]).to eq(RestMan::Continue)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[101]).to eq(RestMan::SwitchingProtocols)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[102]).to eq(RestMan::Processing)
   end

   it 'can success map for 2xx code' do
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[200]).to eq(RestMan::OK)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[201]).to eq(RestMan::Created)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[202]).to eq(RestMan::Accepted)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[203]).to eq(RestMan::NonAuthoritativeInformation)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[204]).to eq(RestMan::NoContent)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[205]).to eq(RestMan::ResetContent)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[206]).to eq(RestMan::PartialContent)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[207]).to eq(RestMan::MultiStatus)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[208]).to eq(RestMan::AlreadyReported)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[226]).to eq(RestMan::IMUsed)
   end

   it 'can success map for 3xx code' do
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[300]).to eq(RestMan::MultipleChoices)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[301]).to eq(RestMan::MovedPermanently)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[302]).to eq(RestMan::Found)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[303]).to eq(RestMan::SeeOther)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[304]).to eq(RestMan::NotModified)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[305]).to eq(RestMan::UseProxy)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[306]).to eq(RestMan::SwitchProxy)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[307]).to eq(RestMan::TemporaryRedirect)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[308]).to eq(RestMan::PermanentRedirect)
   end

   it 'can success map for 4xx code' do
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[400]).to eq(RestMan::BadRequest)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[401]).to eq(RestMan::Unauthorized)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[402]).to eq(RestMan::PaymentRequired)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[403]).to eq(RestMan::Forbidden)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[404]).to eq(RestMan::NotFound)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[405]).to eq(RestMan::MethodNotAllowed)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[406]).to eq(RestMan::NotAcceptable)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[407]).to eq(RestMan::ProxyAuthenticationRequired)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[408]).to eq(RestMan::RequestTimeout)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[409]).to eq(RestMan::Conflict)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[410]).to eq(RestMan::Gone)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[411]).to eq(RestMan::LengthRequired)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[412]).to eq(RestMan::PreconditionFailed)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[413]).to eq(RestMan::PayloadTooLarge)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[414]).to eq(RestMan::URITooLong)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[415]).to eq(RestMan::UnsupportedMediaType)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[416]).to eq(RestMan::RangeNotSatisfiable)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[417]).to eq(RestMan::ExpectationFailed)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[418]).to eq(RestMan::ImATeapot)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[421]).to eq(RestMan::TooManyConnectionsFromThisIP)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[422]).to eq(RestMan::UnprocessableEntity)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[423]).to eq(RestMan::Locked)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[424]).to eq(RestMan::FailedDependency)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[425]).to eq(RestMan::UnorderedCollection)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[426]).to eq(RestMan::UpgradeRequired)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[428]).to eq(RestMan::PreconditionRequired)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[429]).to eq(RestMan::TooManyRequests)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[431]).to eq(RestMan::RequestHeaderFieldsTooLarge)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[449]).to eq(RestMan::RetryWith)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[450]).to eq(RestMan::BlockedByWindowsParentalControls)

      expect(RestMan::ResourceNotFound).to eq(RestMan::NotFound)
      expect(RestMan::RequestEntityTooLarge).to eq(RestMan::PayloadTooLarge)
      expect(RestMan::RequestURITooLong).to eq(RestMan::URITooLong)
      expect(RestMan::RequestedRangeNotSatisfiable).to eq(RestMan::RangeNotSatisfiable)
   end

   it 'can success map for 5xx code' do
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[500]).to eq(RestMan::InternalServerError)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[501]).to eq(RestMan::NotImplemented)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[502]).to eq(RestMan::BadGateway)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[503]).to eq(RestMan::ServiceUnavailable)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[504]).to eq(RestMan::GatewayTimeout)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[505]).to eq(RestMan::HTTPVersionNotSupported)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[506]).to eq(RestMan::VariantAlsoNegotiates)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[507]).to eq(RestMan::InsufficientStorage)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[508]).to eq(RestMan::LoopDetected)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[509]).to eq(RestMan::BandwidthLimitExceeded)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[510]).to eq(RestMan::NotExtended)
      expect(RestMan::Exceptions::EXCEPTIONS_MAP[511]).to eq(RestMan::NetworkAuthenticationRequired)
   end

end
