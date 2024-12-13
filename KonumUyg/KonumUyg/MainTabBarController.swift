//
//  MainTabBarController.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//

import UIKit
import FirebaseAuth

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Giriş yapan kullanıcının UID'sini alıyoruz
        guard let currentUser = Auth.auth().currentUser else {
            return
        }

        // FirebaseHelper ile kullanıcı adını alıyoruz
        FirebaseHelper.fetchUsernameFromFirestore(uid: currentUser.uid) { [weak self] username in
            guard let username = username else {
                print("Username alınamadı")
                return
            }
            
            // ProfileViewController'ı username parametresiyle başlatıyoruz
            let profileVC = ProfileViewController(username: username)
            let mainVC = MainViewController()
            
            // Her bir view controller'ı UINavigationController içine yerleştir
            let profileNavController = UINavigationController(rootViewController: profileVC)
            let mainNavController = UINavigationController(rootViewController: mainVC)
            
            // Navigation bar başlıkları belirleyin
            profileNavController.title = "Profil"
            mainNavController.title = "Ana Sayfa"
            
            // Tab bar item'larını ayarlayın
            profileNavController.tabBarItem = UITabBarItem(title: "Profil", image: UIImage(systemName: "person.circle.fill"), tag: 0)
            mainNavController.tabBarItem = UITabBarItem(title: "Ana Sayfa", image: UIImage(systemName: "house.fill"), tag: 1)
            
            // Tab bar controller'a view controller'ları ekleyin
            self?.viewControllers = [profileNavController, mainNavController]
        }
    }
}
