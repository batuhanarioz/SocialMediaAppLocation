//
//  SceneDelegate.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var navigationController: UINavigationController?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        UITabBar.appearance().backgroundColor = UIColor(red: 142/255, green: 231/255, blue: 164/255, alpha: 1.0)
        
        // Kullanıcı oturum açıp açmadığını kontrol et
        if let currentUser = Auth.auth().currentUser {
            // Kullanıcı giriş yapmışsa UID'yi alıyoruz
            let uid = currentUser.uid

            // Firestore'dan kullanıcı bilgisini almak için query başlatıyoruz
            let db = Firestore.firestore()
            db.collection("users").document(uid).getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching user document: \(error.localizedDescription)")
                    self.showLoginScreen()
                    return
                }
                
                if let document = document, document.exists {
                    // Kullanıcı belgesi varsa, profil sayfasına yönlendir
                    if let username = document.data()?["username"] as? String {
                        let profileVC = ProfileViewController(username: username)
                        let profileNavigationController = UINavigationController(rootViewController: profileVC)
                        profileNavigationController.tabBarItem = UITabBarItem(title: "Profil", image: UIImage(systemName: "person.circle"), tag: 0)

                        let tabBarController = UITabBarController()
                        let mapVC = MapViewController()
                        mapVC.view.backgroundColor = .white
                        mapVC.tabBarItem = UITabBarItem(title: "Harita", image: UIImage(systemName: "location.magnifyingglass"), tag: 1)
                        tabBarController.viewControllers = [profileNavigationController, mapVC]
                        
                        self.window?.rootViewController = tabBarController
                        self.window?.makeKeyAndVisible()
                    } else {
                        print("Username not found in Firestore document.")
                        self.showLoginScreen()
                    }
                } else {
                    print("No user document found.")
                    self.showLoginScreen()
                }
            }
        } else {
            // Giriş yapmamışsa login ekranını göster
            showLoginScreen()
        }
    }

    // Login ekranına yönlendir
    private func showLoginScreen() {
        let loginVC = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginVC)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
    }


    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

