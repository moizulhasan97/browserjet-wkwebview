//
//  LicenseEndpoint.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 24/02/2026.
//

import Foundation

enum LicenseEndpoint: EndpointProtocol {
    /// Shared payload for both `shiftLicenseKey` and `sendEmailToUser` (kept in one type so each
    /// enum case has a single associated value, satisfying `enum_case_associated_values_count`).
    struct ShiftPayload {
        let key: String
        let newPcName: String
        let newMacAddress: String
        let email: String
        let oldPcName: String
    }
    
    case verifyKey(key: String, pcName: String, macAddress: String)
    case generateKey(email: String, password: String)
    case checkExpiry(String)
    case getOldPCDetails(String)
    case shiftLicenseKey(ShiftPayload)
    case sendEmailToUser(ShiftPayload)
    case updateToDatabase(key: String)
    case forgotPassword(email: String)
    case verifyMac(key: String, macAddress: String)
    
    var baseURL: URL { APIEnvironment.current.baseURL }
    
    var path: String { "/License.ashx" }
    
    var method: HTTPMethod { .get }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case let .verifyKey(key, pcName, macAddress):
            return [
                .init(name: "pcname", value: pcName),
                .init(name: "MAC", value: macAddress),
                .init(name: "MethodName", value: "VerifyKey"),
                .init(name: "Key", value: key)
            ]
        case let .generateKey(email, password):
            return [
                .init(name: "MethodName", value: "UserRegistration"),
                .init(name: "Email", value: email),
                .init(name: "Password", value: password)
            ]
        case let .checkExpiry(key):
            return [
                .init(name: "MethodName", value: "expcheck"),
                .init(name: "Key", value: key)
            ]
        case let .getOldPCDetails(key):
            return [
                .init(name: "MethodName", value: "getpcdetails"),
                .init(name: "Key", value: key)
            ]
        case let .shiftLicenseKey(payload):
            return shiftQueryItems(methodName: "updatemachine", payload: payload)
            
        case let .sendEmailToUser(payload):
            return shiftQueryItems(methodName: "Sendmailtouser", payload: payload)
            
        case let .updateToDatabase(key):
            return [
                .init(name: "MethodName", value: "UpdateToMac"),
                .init(name: "UserKey", value: key)
            ]
            
        case let .forgotPassword(email):
            return [
                .init(name: "Email", value: email),
                .init(name: "GetKey", value: "Forgot")
            ]
            
        case let .verifyMac(key, macAddress):
            return [
                .init(name: "MAC", value: macAddress),
                .init(name: "MethodName", value: "VerifyMac"),
                .init(name: "Key", value: key),
                .init(name: "From Mac", value: "True")
            ]
        }
    }
    
    private func shiftQueryItems(methodName: String, payload: ShiftPayload) -> [URLQueryItem] {
        [
            .init(name: "MethodName", value: methodName),
            .init(name: "Key", value: payload.key),
            .init(name: "NewMachine", value: payload.newPcName),
            .init(name: "MacAddress", value: payload.newMacAddress),
            .init(name: "Email", value: payload.email),
            .init(name: "machine", value: payload.oldPcName)
        ]
    }
    
    // used for both
    // - license renewal
    // - trial expired
    static func licenseExpiredPaymentURL(email: String) -> URL {
        let base = APIEnvironment.current.baseURL
        var components = URLComponents(url: base.appendingPathComponent("License.ashx"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "Method", value: "PayRenewal"),
            URLQueryItem(name: "Email", value: email.trimmingCharacters(in: .whitespacesAndNewlines))
        ]
        return components?.url ?? base.appendingPathComponent("License.ashx")
    }
}
