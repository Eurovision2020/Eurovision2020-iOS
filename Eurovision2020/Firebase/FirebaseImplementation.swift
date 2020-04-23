//
//  FirebaseImplementation.swift
//  Eurovision2020
//
//  Created by Sacha DSO on 12/04/2020.
//  Copyright © 2020 MarsacProductions. All rights reserved.
//

import Foundation
import Combine
import Networking
import Firebase
import PhoneNumberKit

class FirebaseImplementation: NetworkingService {
    
    func startService() {
        FirebaseApp.configure()
    }
    
    var network = NetworkingClient(baseURL: "https://us-central1-eurovision2020-ea486.cloudfunctions.net/api/v1")
    
    func askForPhoneNumberVerification(number: PhoneNumber) -> AnyPublisher<Void, Error> {
        Future { promise in
            // Localize sms sent to user's laguage
            Auth.auth().languageCode = Locale.current.languageCode ?? "en"
            
            // Start SMS confirmation
            PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil) { [weak self] verificationID, error in
                    if let e = error {
                        promise(.failure(e))
                    } else {
                        self?.currentVerificationID = verificationID
                        promise(.success(()))
                    }
            }
        }.eraseToAnyPublisher()
    }
        
    var currentVerificationID: String?
    func confirmPhoneNumberWithCode(code: SMSCode) -> AnyPublisher<Void, Error> {
        let verificationID = currentVerificationID ?? ""
        return Future { promise in
            let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
            Auth.auth().signIn(with: credential) { _, error in
                if let e = error {
                    promise(.failure(e))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private var cachedCurrentUser: User?
    
    func getCurrentUser() -> User? {
        if let cachedUser = cachedCurrentUser, Auth.auth().currentUser != nil {
            return cachedUser
        }

        if let cuPhoneNumber = Auth.auth().currentUser?.phoneNumber {
            let phoneNumberKit = PhoneNumberKit()
            let parsedNumber = try? phoneNumberKit.parse(cuPhoneNumber)
            
            if let regionID = parsedNumber?.regionID {
                let user = User(countryCode: regionID, phoneNumber: cuPhoneNumber)
                cachedCurrentUser = user
                return cachedCurrentUser
            }
        }

        return nil
    }
    
    func logout() {
        try? Auth.auth().signOut()
    }
    
    func fetchSongs() -> AnyPublisher<[Song], Error> {
        get("/songs").map { (firebaseSongs: [FirebaseSong]) -> [Song] in
            firebaseSongs.map { $0 as Song }
        }.eraseToAnyPublisher()
    }
    
    func sendVotes(_ votes:[String]) -> AnyPublisher<Void, Error> {
        fetchIdToken().then { [unowned self] idToken in
            self.network.headers["Authorization"] = idToken
            return self.network.post("/vote", params: ["votes": votes])
        }.eraseToAnyPublisher()
    }
    
    private func fetchIdToken() -> Future<String, Error> {
        Future<String, Error> { promise in
            Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
                if let error = error {
                    promise(.failure(error))
                } else if let idToken = idToken {
                    promise(.success(idToken))
                }
            }
        }
    }
}



final class FirebaseSong: Song, NetworkingJSONDecodable, Decodable {
    
    let number: Int
    let title: String
    let link:  String
    var country: Country?
    
    enum CodingKeys: String, CodingKey {
        case number = "number"
        case title = "title"
        case country = "country"
        case link = "link"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)
        link = try container.decode(String.self, forKey: .link)
        country = try container.decode(FirebaseCountry.self, forKey: .country)
    }
}

struct FirebaseCountry: Country, Decodable {
    var code = ""
    var name = ""
}
