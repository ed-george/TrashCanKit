import Foundation
import RequestKit

// MARK: request

public extension TrashCanKit {
    public func refreshToken(session: RequestKitURLSession, oauthConfig: OAuthConfiguration, refreshToken: String, completion: (response: Response<TokenConfiguration>) -> Void) -> URLSessionDataTaskProtocol? {
        let request = TokenRouter.RefreshToken(oauthConfig, refreshToken).URLRequest
        var task: URLSessionDataTaskProtocol?
        if let request = request {
            task = session.dataTaskWithRequest(request) { data, response, err in
                guard let response = response as? NSHTTPURLResponse else { return }
                guard let data = data else { return }
                do {
                    let responseJSON = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    if let responseJSON = responseJSON as? [String: AnyObject] {
                        if response.statusCode != 200 {
                            let errorDescription = responseJSON["error_description"] as? String ?? ""
                            let error = NSError(domain: TrashCanKitErrorDomain, code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                            completion(response: Response.Failure(error))
                        } else {
                            let tokenConfig = TokenConfiguration(json: responseJSON)
                            completion(response: Response.Success(tokenConfig))
                        }
                    }
                }
            }
            task?.resume()
        }
        return task
    }
}

public enum TokenRouter: Router {
    case RefreshToken(OAuthConfiguration, String)

    public var configuration: Configuration {
        switch self {
        case .RefreshToken(let config, _): return config
        }
    }

    public var method: HTTPMethod {
        return .POST
    }

    public var encoding: HTTPEncoding {
        return .FORM
    }

    public var params: [String: AnyObject] {
        switch self {
        case .RefreshToken(_, let token):
            return ["refresh_token": token, "grant_type": "refresh_token"]
        }
    }

    public var path: String {
        switch self {
        case .RefreshToken(_, _):
            return "site/oauth2/access_token"
        }
    }

    public var URLRequest: NSURLRequest? {
        switch self {
        case .RefreshToken(let config, _):
            let url = NSURL(string: path, relativeToURL: NSURL(string: config.webEndpoint))
            let components = NSURLComponents(URL: url!, resolvingAgainstBaseURL: true)
            return request(components!, parameters: params)
        }
    }
}
