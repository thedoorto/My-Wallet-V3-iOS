//
//  Biometry.swift
//  PlatformUIKit
//
//  Created by Daniel Huri on 18/10/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import LocalAuthentication
import Localization
import PlatformKit

public struct Biometry {
    
    public enum BiometryError: Error {
        private typealias LocalizedString = LocalizationConstants.Biometry
        
        case authenticationFailed
        case passcodeNotSet
        case biometryLockout
        case biometryNotAvailable
        case biometryNotEnrolled
        
        case appCancel
        case systemCancel
        case userCancel
        case userFallback
        case general

        /// A user message corresponding to the error
        public var localizedDescription: String {
            switch self {
            case .authenticationFailed:
                return LocalizedString.authenticationFailed
            case .passcodeNotSet:
                return LocalizedString.passcodeNotSet
            case .biometryLockout:
                return LocalizedString.biometricsLockout
            case .biometryNotAvailable:
                return LocalizedString.biometricsNotSupported
            case .biometryNotEnrolled:
                return LocalizedString.touchIDEnableInstructions
            case .general:
                return LocalizedString.genericError
            case .appCancel,
                 .systemCancel,
                 .userCancel,
                 .userFallback:
                return ""
            }
        }
        
        /// Initializes with error, expects the error to have `code`
        /// compatible code to `LAError.Code.rawValue`
        init(with error: Error) {
            let code = (error as NSError).code
            self.init(with: code)
        }
        
        /// Initializes with expected `LAError.Code`'s `rawValue`
        init(with rawCodeValue: Int) {
            if let localAuthenticationCode = LAError.Code(rawValue: rawCodeValue) {
                self.init(with: localAuthenticationCode)
            } else {
                self = .general
            }
        }
        
        /// Initializes with `LAError.Code` value
        init(with error: LAError.Code) {
            switch error {
            case .authenticationFailed:
                self = .authenticationFailed
            case .appCancel:
                self = .appCancel
            case .passcodeNotSet:
                self = .passcodeNotSet
            case .systemCancel:
                self = .systemCancel
            case .userCancel:
                self = .userCancel
            case .userFallback:
                self = .userFallback
            case .touchIDLockout:
                self = .biometryLockout
            case .touchIDNotAvailable:
                self = .biometryNotAvailable
            case .touchIDNotEnrolled:
                self = .biometryNotEnrolled
            case .invalidContext,
                 .notInteractive:
                self = .general
            @unknown default:
                self = .general
            }
        }
    }
    
    // MARK: - Types

    public enum Reason {
        case enterWallet
        
        var localized: String {
            switch self {
            case .enterWallet:
                return LocalizationConstants.Biometry.authenticationReason
            }
        }
    }
    
    /// Indicates the current biometrics configuration state
    public enum Status {
        
        /// Not configured on device but there is no restriction for configuring one
        case configurable(BiometryType)
        
        /// Configured on the device and in app
        case configured(BiometryType)
        
        /// Cannot be configured because the device do not support it,
        /// or because the user hasn't enabled it, or because that feature is not remotely
        case unconfigurable(Error)
        
        /// Returns `true` if biometrics is configurable
        public var isConfigurable: Bool {
            switch self {
            case .configurable:
                return true
            case .configured, .unconfigurable:
                return false
            }
        }
        
        /// Returns `true` if biometrics is configured
        public var isConfigured: Bool {
            switch self {
            case .configured:
                return true
            case .configurable, .unconfigurable:
                return false
            }
        }
        
        /// Returns associated `BiometricsType` if any
        public var biometricsType: BiometryType {
            switch self {
            case .configurable(let type):
                return type
            case .configured(let type):
                return type
            case .unconfigurable:
                return .none
            }
        }
    }
    
    /// A type of biomety authenticator
    public enum BiometryType {

        /// The device supports Touch ID.
        case touchID

        /// The device supports Face ID.
        case faceID

        /// The device does not support biometry.
        case none

        init(with systemType: LABiometryType) {
            switch systemType {
            case .faceID:
                self = .faceID
            case .touchID:
                self = .touchID
            case .none:
                self = .none
            @unknown default:
                self = .none
            }
        }

        public var localizedName: String? {
            switch self {
            case .faceID:
                return LocalizationConstants.faceId
            case .touchID:
                return LocalizationConstants.touchId
            case .none:
                return nil
            }
        }
        
        public var isValid: Bool {
            self != .none
        }
    }
    
    /// Represents `LAContext` result on calling `canEvaluatePolicy` for biometrics
    public enum EvaluationError: Error {
        
        /// Wraps
        case system(BiometryError)
        case notAllowed
        
        public var localizedDescription: String {
            switch self {
            case .system(let error):
                return error.localizedDescription
            case .notAllowed:
                return LocalizationConstants.Biometry.notConfigured
            }
        }
    }    
}
