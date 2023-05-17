// 06.05.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © __YEAR__ amaider. All rights reserved.

import Foundation
import Network

class HueBridgeDiscovery: NSObject {
    
    private let serviceType = "_hue._tcp"
    private let domain = "local"
    private var browser: NetServiceBrowser?
    private var services: [NetService] = []
    
    /// completion: (Name, IP Address)
    var completion: (String, String) -> Void = { _, _ in }
    
    func startDiscovery(completion: @escaping (String, String) -> Void) {
        self.completion = completion
        
        self.services = []
        
        self.browser = NetServiceBrowser()
        self.browser?.delegate = self
        self.browser?.searchForServices(ofType: serviceType, inDomain: domain)
    }

}

extension HueBridgeDiscovery: NetServiceBrowserDelegate, NetServiceDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        self.services.append(service)
        
        if !moreComing {
            browser.stop()
            
            /// resolve IPs
            for service in services {
                service.delegate = self
                service.resolve(withTimeout: 5.0)
            }
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("Hue bridge removed")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        if let error = errorDict[NetService.errorCode] {
            print("Failed to search for Hue bridge with error code: \(error)")
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        if let error = errorDict[NetService.errorCode] {
            print("Failed to resolve Hue bridge with error code: \(error)")
        }
    }
    
    func netServiceDidResolveAddress(_ service: NetService) {
        // Get the IP address of the hue bridge
        guard let addresses = service.addresses, let address = addresses.first else {
            completion(service.name, "?")
            return
        }
        
        // Convert the IP address to a human-readable string
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let sockAddr = address.withUnsafeBytes { pointer in
            return pointer.bindMemory(to: sockaddr.self).baseAddress!
        }
        let sockAddrLen = socklen_t(address.count)
        guard getnameinfo(sockAddr, sockAddrLen, &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
            completion(service.name, "?")
            return
        }
        
        let ipAddress: String = .init(cString: hostname)
        
        completion(service.name, ipAddress)
    }
    
}

