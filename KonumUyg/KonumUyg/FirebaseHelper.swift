//
//  FirebaseHelper.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//


import FirebaseFirestore

class FirebaseHelper {
    
    // Firebase'den username verisini almak için kullanılacak fonksiyon
    static func fetchUsernameFromFirestore(uid: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("Doküman bulunamadı")
                completion(nil)
                return
            }
            
            // "username" alanını alıyoruz
            let username = data["username"] as? String
            completion(username)
        }
    }
}
