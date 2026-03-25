//
//  LicenseEndpoint.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

enum LicenseEndpoint: EndpointProtocol {

    case verifyKey(key: String, pcName: String, macAddress: String)
    case generateKey(email: String, password: String)
    case checkExpiry(String)
    case getOldPCDetails(String)
    case shiftLicenseKey(key: String, newPcName: String, newMacAddress: String, email: String, oldPcName: String)
    case sendEmailToUser(key: String, newPcName: String, newMacAddress: String, email: String, oldPcName: String)
    case updateToDatabase(key: String)
    case forgotPassword(email: String)

    var baseURL: URL { APIEnvironment.current.baseURL }

    var path: String { "/License.ashx" }

    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .verifyKey(let key, let pcName, let macAddress):
            return [
                .init(name: "pcname", value: pcName),
                .init(name: "MAC", value: macAddress),
                .init(name: "MethodName", value: "VerifyKey"),
                .init(name: "Key", value: key)
            ]
        case .generateKey(let email, let password):
            return [
                .init(name: "MethodName", value: "UserRegistration"),
                .init(name: "Email", value: email),
                .init(name: "Password", value: password)
            ]
        case .checkExpiry(let key):
            return [
                .init(name: "MethodName", value: "expcheck"),
                .init(name: "Key", value: key)
            ]
        case .getOldPCDetails(let key):
            return [
                .init(name: "MethodName", value: "getpcdetails"),
                .init(name: "Key", value: key)
            ]
        case .shiftLicenseKey(let key, let newPcName, let newMacAddress, let email, let oldPcName):
            return [
                .init(name: "MethodName", value: "updatemachine"),
                .init(name: "Key", value: key),
                .init(name: "NewMachine", value: newPcName),
                .init(name: "MacAddress", value: newMacAddress),
                .init(name: "Email", value: email),
                .init(name: "machine", value: oldPcName),
            ]
            
        case .sendEmailToUser(let key, let newPcName, let newMacAddress, let email, let oldPcName):
            return [
                .init(name: "MethodName", value: "Sendmailtouser"),
                .init(name: "Key", value: key),
                .init(name: "NewMachine", value: newPcName),
                .init(name: "MacAddress", value: newMacAddress),
                .init(name: "Email", value: email),
                .init(name: "machine", value: oldPcName),
            ]
        
        case .updateToDatabase(let key):
            return [
                .init(name: "MethodName", value: "UpdateToMac"),
                .init(name: "UserKey", value: key),
            ]

        case .forgotPassword(let email):
            return [
                .init(name: "Email", value: email),
                .init(name: "GetKey", value: "Forgot"),
            ]
        }
    }
    
    // used for both
    // - license renewal
    // - trial expired
    static func licenseExpiredPaymentURL(email: String) -> URL {
        let base = APIEnvironment.current.baseURL
        var components = URLComponents(url: base.appendingPathComponent("License.ashx"), resolvingAgainstBaseURL: false)
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryValueAllowed) ?? email
        components?.queryItems = [
            URLQueryItem(name: "Method", value: "PayRenewal"),
            URLQueryItem(name: "Email", value: encodedEmail)
        ]
        return components?.url ?? base
    }
}

private extension CharacterSet {
    static var urlQueryValueAllowed: CharacterSet {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&+")
        return set
    }
}
