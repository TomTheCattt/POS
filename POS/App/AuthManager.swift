//
//  AuthManager.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 10/5/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseCrashlytics

class AuthManager: ObservableObject {
    @AppStorage("userUID") private var _userUID: String = ""
    @Published var currentUser: AppUser? {
        didSet {
            objectWillChange.send()
        }
    }

    private let firestore = Firestore.firestore()

    var userUID: String {
        get { _userUID }
        set {
            _userUID = newValue
            objectWillChange.send()
        }
    }

    var isAuthenticated: Bool {
        return currentUser != nil
    }

    init() {
        if !_userUID.isEmpty {
            fetchCurrentUser()
        }
    }

    func saveUID(_ uid: String) {
        userUID = uid
        fetchCurrentUser()
    }

    func logout() {
        userUID = ""
        currentUser = nil
    }

    func fetchCurrentUser() {
        let userRef = firestore.collection("users").document(userUID)

        userRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
                return
            }

            guard let document = snapshot, document.exists else {
                return
            }

            do {
                let appUser = try document.data(as: AppUser.self)
                DispatchQueue.main.async {
                    self?.currentUser = appUser
                }
            } catch {
                Crashlytics.crashlytics().record(error: error)
            }
        }
    }
}
