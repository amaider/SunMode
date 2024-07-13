// 29.05.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © __YEAR__ amaider. All rights reserved.

import Foundation

class HueAPIv2URLSessioDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust: SecTrust = challenge.protectionSpace.serverTrust else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        return (.useCredential, URLCredential(trust: serverTrust))
    }
}
