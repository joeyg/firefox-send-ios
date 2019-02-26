/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CryptoSwift

class Keychain {
    var nonce: String
    var iv: [UInt8]
    var rawSecret: [UInt8]

    var encryptKey: [UInt8]?
    var metadataKey: [UInt8]?
    var authKey: [UInt8]?

    convenience init() {
        self.init(secretKeyB64: "ECogp0rQtYjGgKqBfwxw3w==", nonce: "yRCdyQ1EMSA3mo4rqSkuNQ==", ivB64: nil)
    }

    init(secretKeyB64: String?,
         nonce: String?,
         ivB64: String?) {

        self.nonce = nonce ?? "yRCdyQ1EMSA3mo4rqSkuNQ=="
        self.iv = ivB64?.bytes ?? AES.randomIV(12)
        self.rawSecret = Data(base64Encoded: secretKeyB64 ?? "", options: .init(rawValue: 0))?.bytes ?? AES.randomIV(16)

        do {
            self.encryptKey = try HKDF(password: self.rawSecret,
                               salt: Array<UInt8>(),
                               info: "encryption".bytes,
                               keyLength: 16,
                               variant: HMAC.Variant.sha256).calculate()

            self.metadataKey = try HKDF(password: self.rawSecret,
                                   salt: Array<UInt8>(),
                                   info: "metadata".bytes,
                                   keyLength: 16,
                                   variant: HMAC.Variant.sha256).calculate()

            self.authKey = try HKDF(password: self.rawSecret,
                                   salt: Array<UInt8>(),
                                   info: "authentication".bytes,
                                   keyLength: 64,
                                   variant: HMAC.Variant.sha256).calculate()

        } catch let error {
            debugPrint(error)
        }
    }

    func authHeader() -> String? {
        if let a = self.auth() {
            return "send-v1 \(a)"
        }

        return nil
    }

    func auth() -> String? {
        guard let authKey = self.authKey else { return nil }

        do {
            let hmac = HMAC(key: authKey, variant: .sha256)
            if let nonceBytes = Data(base64Encoded: self.nonce , options: .init(rawValue: 0))?.bytes {
                let sig = try hmac.authenticate(nonceBytes)
                return self.toBase64(sig)
            }
        } catch let error {
            debugPrint(error)
        }

        return nil
    }

    func authKeyB64() -> String? {
        guard let authKey = self.authKey else { return nil }
        return self.toBase64(authKey)
    }

    func encryptFile(plaintext: Data) -> Data? {
        guard let encryptKey = self.encryptKey else { return nil }

        do {
            let aes = try AES(key: encryptKey, blockMode: GCM(iv: self.iv, additionalAuthenticatedData: nil, tagLength: 128, mode: .combined))
            let ciphertext = try aes.encrypt(plaintext.bytes)
            return Data(bytes: ciphertext)
        } catch let error {
            debugPrint(error)
        }

        return nil
    }

    func encryptMetadata(name: String, type: String?) -> String? {
        guard let metadataKey = self.metadataKey else { return nil }

        let dataType = type ?? "application/octet-stream"

        guard let ivString = self.toBase64(self.iv) else { return nil }

        do {
            let aes = try AES(key: metadataKey, blockMode: GCM(iv: Array<UInt8>(repeating: 0, count: 12), additionalAuthenticatedData: nil, tagLength: 128, mode: .combined), padding: .noPadding)
            let ciphertext = try aes.encrypt("{\"iv\":\"\(ivString)\", \"name\":\"\(name)\", \"type\":\"\(dataType)\"}".bytes)
            return self.toBase64(ciphertext)
        } catch let error {
            debugPrint(error)
        }

        return nil
    }

    func toBase64(_ data: [UInt8]) -> String? {
        return data.toBase64()?
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
