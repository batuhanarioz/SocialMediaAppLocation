//
//  MapViewController.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//

import UIKit
import MapKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var topSeparatorLine: UIView!
    var bottomSeparatorLine: UIView!
    
    private var mapView: MKMapView!
    private var collectionView: UICollectionView!
    private var followedUsers: [(uid: String, username: String, avatarUrl: String?, latitude: CLLocationDegrees?, longitude: CLLocationDegrees?)] = []
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    private var db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupMapView()
        setupCollectionView()
        fetchFollowedUsers()
        setupLocationManager()
        setupFollowedUsersListener() // Listener başlatılıyor
        // Tab bar ve collection view arasında iki adet çizgi ekleyelim
        addSeparatorLine(atTop: true)  // Üst kısım için
        addSeparatorLine(atTop: false) // Alt kısım için
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Layout güncellenince çizgileri yeniden yerleştiriyoruz
        topSeparatorLine.frame = CGRect(x: 0, y: collectionView.frame.origin.y - 1, width: view.frame.width, height: 1)
        bottomSeparatorLine.frame = CGRect(x: 0, y: collectionView.frame.origin.y + collectionView.frame.height, width: view.frame.width, height: 1)
    }

    func addSeparatorLine(atTop: Bool) {
        // Ayırıcı çizgi için bir UIView oluşturuyoruz
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.lightGray // Gri renk
        
        // Çizgiyi view'e ekliyoruz
        view.addSubview(separatorLine)
        
        if atTop {
            topSeparatorLine = separatorLine
        } else {
            bottomSeparatorLine = separatorLine
        }
    }


    private func setupMapView() {
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .follow
        view.addSubview(mapView)
    }

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Kullanıcının konumunu aldığımızda çağrılır
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Kullanıcının mevcut konumunu kaydedin
        currentLocation = location

        // Firebase'e konumu güncelle
        updateLocationInFirebase(location: location)
        
        // Kendi konumunuzu `followedUsers` dizisinde güncelleyin
        if let index = followedUsers.firstIndex(where: { $0.uid == Auth.auth().currentUser?.uid }) {
            followedUsers[index].latitude = location.coordinate.latitude
            followedUsers[index].longitude = location.coordinate.longitude
        } else {
            // Eğer kullanıcı kendi konumunu dizide bulamazsa, ekle
            if let currentUserUID = Auth.auth().currentUser?.uid,
               let currentUser = followedUsers.first(where: { $0.uid == currentUserUID }) {
                followedUsers.insert((
                    uid: currentUserUID,
                    username: currentUser.username,
                    avatarUrl: currentUser.avatarUrl,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ), at: 0)
            }
        }

        // Kendi konumunuz için haritaya anotasyon ekleyin veya güncelleyin
        if let annotation = mapView.annotations.first(where: { ($0 as? UserAnnotation)?.title == "Siz" }) as? UserAnnotation {
            // Eğer mevcut bir anotasyon varsa, konumu güncelleyin
            annotation.coordinate = location.coordinate
        } else {
            // Eğer mevcut bir anotasyon yoksa, yeni bir tane ekleyin
            let annotation = UserAnnotation(
                coordinate: location.coordinate,
                title: "Siz",
                avatarUrl: followedUsers.first(where: { $0.uid == Auth.auth().currentUser?.uid })?.avatarUrl
            )
            mapView.addAnnotation(annotation)
        }
    }


    // Eğer bir hata olursa çağrılır
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Konum alınamadı: \(error.localizedDescription)")
    }
    
    private func updateLocationInFirebase(location: CLLocation) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        db.collection("users").document(currentUserUID).setData([
            "latitude": latitude,
            "longitude": longitude
        ], merge: true) { error in
            if let error = error {
                print("Konum Firebase'e kaydedilirken hata oluştu: \(error.localizedDescription)")
            } else {
                print("Konum başarıyla kaydedildi.")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let identifier = "UserLocation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false // Ek bilgi gösterimini kapatıyoruz
            } else {
                annotationView?.annotation = annotation
            }
            
            // Kullanıcı avatarını ekliyoruz
            if let currentUser = followedUsers.first(where: { $0.uid == Auth.auth().currentUser?.uid }),
               let avatarUrl = currentUser.avatarUrl,
               let url = URL(string: avatarUrl) {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                imageView.layer.cornerRadius = 20
                imageView.layer.masksToBounds = true
                imageView.contentMode = .scaleAspectFill

                // Avatar resmi yükleniyor
                loadImage(from: url) { image in
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }

                annotationView?.addSubview(imageView)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            } else {
                // Varsayılan bir simge kullan
                return nil
            }

            return annotationView
        }

        // Takip edilen kullanıcılar için varsayılan görünüm
        if let userAnnotation = annotation as? UserAnnotation {
            let identifier = "UserAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: userAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = userAnnotation
            }

            if let avatarUrl = userAnnotation.avatarUrl, let url = URL(string: avatarUrl) {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                imageView.layer.cornerRadius = 20
                imageView.layer.masksToBounds = true
                imageView.contentMode = .scaleAspectFill

                loadImage(from: url) { image in
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }

                annotationView?.addSubview(imageView)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            } else {
                annotationView?.image = UIImage(systemName: "person.circle")
            }

            return annotationView
        }

        return nil
    }



    private func addPinsToMap() {
        mapView.removeAnnotations(mapView.annotations) // Önceki annotasyonları temizle

        for user in followedUsers {
            guard let latitude = user.latitude, let longitude = user.longitude else {
                print("\(user.username) için konum bilgisi eksik.")
                continue
            }

            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = UserAnnotation(coordinate: coordinate, title: user.username, avatarUrl: user.avatarUrl)
            mapView.addAnnotation(annotation)
        }
    }


    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            completion(UIImage(data: data))
        }
        task.resume()
    }



    func focusOnUserLocation(user: (latitude: CLLocationDegrees, longitude: CLLocationDegrees)) {
        let coordinate = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }

    private func setupFollowedUsersListener() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUserUID).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error listening for followed users changes: \(error.localizedDescription)")
                return
            }
            
            guard let self = self, let snapshot = snapshot, snapshot.exists,
                  let following = snapshot.get("following") as? [String] else {
                return
            }
            
            // Diziyi sıfırla ve tekrar yükle
            self.followedUsers = [] // Eski listeyi temizle
            for uid in following {
                self.fetchUserData(uid: uid)
            }
        }
    }



    // MARK: - Setup Collection View
        private func setupCollectionView() {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 10
            layout.itemSize = CGSize(width: 80, height: 100)
            
            collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(UserCollectionViewCell.self, forCellWithReuseIdentifier: "UserCell")
            collectionView.backgroundColor = UIColor(red: 142/255, green: 231/255, blue: 164/255, alpha: 1.0)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.showsHorizontalScrollIndicator = false
            
            view.addSubview(collectionView)
            
            NSLayoutConstraint.activate([
                collectionView.heightAnchor.constraint(equalToConstant: 100),
                collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
    

        // MARK: - Fetch Followed Users
    private func fetchFollowedUsers() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }

        // Öncelikle kendi kullanıcı bilgimizi yükle
        db.collection("users").document(currentUserUID).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching current user data: \(error.localizedDescription)")
                return
            }

            guard let self = self, let document = document, document.exists,
                  let username = document.get("username") as? String else {
                return
            }

            let avatarUrl = document.get("avatarUrl") as? String

            // Dizinin ilk elemanı olarak kullanıcının kendisini ekle
            self.followedUsers = [(uid: currentUserUID, username: username, avatarUrl: avatarUrl, latitude: currentLocation?.coordinate.latitude, longitude: currentLocation?.coordinate.longitude)]

            // Daha sonra takip edilen kullanıcıları yükle
            self.db.collection("users").document(currentUserUID).getDocument { [weak self] document, error in
                if let error = error {
                    print("Error fetching followed users: \(error.localizedDescription)")
                    return
                }

                guard let self = self, let document = document, document.exists,
                      let following = document.get("following") as? [String] else {
                    return
                }

                // Takip edilen kullanıcıları yükle
                for uid in following {
                    self.fetchUserData(uid: uid)
                }
            }
        }
    }


    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            guard let self = self, let document = document, document.exists,
                  let username = document.get("username") as? String else {
                return
            }

            let avatarUrl = document.get("avatarUrl") as? String
            let latitude = document.get("latitude") as? CLLocationDegrees
            let longitude = document.get("longitude") as? CLLocationDegrees

            // Kullanıcının zaten dizide olup olmadığını kontrol et
                    if !self.followedUsers.contains(where: { $0.uid == uid }) {
                        self.followedUsers.append((uid: uid, username: username, avatarUrl: avatarUrl, latitude: latitude, longitude: longitude))
                    } else {
                        // Eğer kullanıcı zaten varsa, yeni bilgileri güncelle
                        if let index = self.followedUsers.firstIndex(where: { $0.uid == uid }) {
                            self.followedUsers[index] = (uid: uid, username: username, avatarUrl: avatarUrl, latitude: latitude, longitude: longitude)
                        }
                    }

                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.addPinsToMap() // Haritayı güncelle
                    }
        }
    }


        // MARK: - UICollectionView DataSource & Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return followedUsers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserCollectionViewCell
        let user = followedUsers[indexPath.item]
        
        cell.backgroundColor = UIColor(red: 142/255, green: 231/255, blue: 164/255, alpha: 1.0)
        cell.contentView.backgroundColor = UIColor(red: 142/255, green: 231/255, blue: 164/255, alpha: 1.0)

        
        cell.configure(with: user.username, avatarUrl: user.avatarUrl)

        // Eğer bu kullanıcı kendimizse, hücreyi özelleştir
        if indexPath.item == 0 {
            cell.backgroundColor = UIColor.systemGray6 // Özel arka plan rengi
        } else {
            cell.backgroundColor = .white
        }

        return cell
    }


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedUser = followedUsers[indexPath.row]

        // Eğer kullanıcı kendi profiline tıkladıysa
        if indexPath.row == 0 {
            if let currentLocation = currentLocation {
                focusOnUserLocation(user: (latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude))
            } else {
                print("Kendi konumunuz henüz alınamadı.")
            }
        } else {
            // Takip edilen bir kullanıcıya tıklandıysa
            if let latitude = selectedUser.latitude, let longitude = selectedUser.longitude {
                focusOnUserLocation(user: (latitude: latitude, longitude: longitude))
            } else {
                print("\(selectedUser.username) için konum bulunamadı.")
            }
        }
    }



}




class UserAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    let title: String?
    let avatarUrl: String?

    init(coordinate: CLLocationCoordinate2D, title: String?, avatarUrl: String?) {
        self.coordinate = coordinate
        self.title = title
        self.avatarUrl = avatarUrl
        super.init()
    }
}
