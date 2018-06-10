//
//  HomeViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/14.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import SearchTextField
import Firebase
import CoreLocation

class HomeViewController: UIViewController {

    @IBOutlet weak var searchTextField: SearchTextField! {
        didSet {
            self.searchTextField.delegate = self
            self.searchTextField.startVisible = true
            self.searchTextField.maxNumberOfResults = 1
            self.searchTextField.theme.font = UIFont.preferredFont(forTextStyle: .body)
            self.searchTextField.theme.cellHeight = 44
            self.searchTextField.placeholder = "駅名・レストラン名から検索"
            self.searchTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
            self.searchTextField.highlightAttributes = [
                NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .headline)
            ]
            self.searchTextField.itemSelectionHandler = { [weak self] filteredResults, itemPosition in
                guard let strongSelf = self else { return }
                guard let item = filteredResults[itemPosition] as? SearhableItem else { return }
                strongSelf.searchTextField.text = item.title
                if let station = item.station {
                    strongSelf.selectedRestaurant = nil
                    strongSelf.selectedStation = station
                    strongSelf.search()
                } else if let restaurant = item.restaurant {
                    strongSelf.selectedStation = nil
                    strongSelf.selectedRestaurant = restaurant
                    strongSelf.search()
                } else if item.isUserLocation {
                    strongSelf.selectedRestaurant = nil
                    strongSelf.selectedStation = nil
                    strongSelf.requestLocation()
                }
            }
        }
    }

    @IBAction func searchTexFieldDidChange(_ sender: Any) {
        guard let text = self.searchTextField.text else { return }
        if text.count > 0 && self.searchTextField.maxNumberOfResults == 1 {
            self.searchTextField.maxNumberOfResults = 10
        } else if text.count == 0 && self.searchTextField.maxNumberOfResults == 10 {
            self.searchTextField.maxNumberOfResults = 1
            self.searchTextField.theme.cellHeight = 44
        }
    }

    @IBAction func searchButton(_ sender: Any) {
        self.search()
    }

    var alertController: UIAlertController?
    var locationManager: CLLocationManager?
    var myPlace: CLLocation? {
        didSet {
            if self.myPlace != nil {
                self.search()
            }
        }
    }

    var ref: DatabaseReference!

    var searcableItems = [SearhableItem]()
    var stations = [Station]()
    var restaurants = [Restaurant]()
    var selectedStation: Station?
    var selectedRestaurant: Restaurant?

    var keyboardSize: CGSize?

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)

        self.searcableItems.append(contentsOf: [SearhableItem(data: SearhableItemData.userLocation("現在地から検索"))])
        self.searchTextField.filterItems(self.searcableItems)
        self.ref = Database.database().reference()
        self.ref.child("stations").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let station = Station(snapshot: snapshot) {
                    strongSelf.stations.append(station)
                }
            }
            let searchableStations = strongSelf.stations.map { (station) -> SearhableItem in
                return SearhableItem(data: SearhableItemData.station(station))
            }
            strongSelf.searcableItems.append(contentsOf: searchableStations)
            strongSelf.searchTextField.filterItems(strongSelf.searcableItems)
        })
        self.ref.child("restaurants").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let restaurant = Restaurant(snapshot: snapshot) {
                    strongSelf.restaurants.append(restaurant)
                }
            }
            let searchableRestaurants = strongSelf.restaurants.map { restaurant -> SearhableItem in
                return SearhableItem(data: SearhableItemData.restaurant(restaurant))
            }
            strongSelf.searcableItems.append(contentsOf: searchableRestaurants)
            strongSelf.searchTextField.filterItems(strongSelf.searcableItems)
        })

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.myPlace != nil && self.selectedRestaurant == nil && self.selectedStation == nil {
            self.searchTextField.text = ""
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size {
            if self.keyboardSize == nil {
                self.keyboardSize = keyboardSize
            }
            if self.view.frame.origin.y == (UIApplication.shared.statusBarFrame.height + (self.navigationController?.navigationBar.frame.height)!) {
                self.view.frame.origin.y -= (self.keyboardSize != nil) ? (self.keyboardSize?.height)! : keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        let baseY = (UIApplication.shared.statusBarFrame.height + (self.navigationController?.navigationBar.frame.height)!)
        if self.view.frame.origin.y < baseY {
            self.view.frame.origin.y = baseY
        }
    }

    var isSeaching = false

    func search() {
        if !isSeaching {
            self.isSeaching = true
            self.dismissKeyboard()
            if let station = self.selectedStation {
                guard let rvc = storyboard?.instantiateViewController(withIdentifier: "resultViewController") as? ResultViewController else { assert(false) }
                rvc.station = station
                self.navigationController?.pushViewController(rvc, animated: true)
            } else if let restaurant = self.selectedRestaurant {
                guard let rvc = storyboard?.instantiateViewController(withIdentifier: "restaurantViewController") as? RestaurantViewController else { assert(false) }
                rvc.restaurant = restaurant
                self.navigationController?.pushViewController(rvc, animated: true)
            } else if let myPlace = self.myPlace {
                if self.navigationController?.viewControllers.count == 1 {
                    guard let rvc = storyboard?.instantiateViewController(withIdentifier: "resultViewController") as? ResultViewController else { assert(false) }
                    rvc.myPlace = myPlace
                    self.navigationController?.pushViewController(rvc, animated: true)
                }
            }
            self.isSeaching = false
        }
    }

    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
}

extension HomeViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.search()
        return true
    }

}

extension HomeViewController: CLLocationManagerDelegate {

    func requestLocation() {
        if self.locationManager == nil {
            self.locationManager = CLLocationManager()
            self.locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager!.delegate = self
            self.locationManager!.requestWhenInUseAuthorization()
        }
        self.locationManager!.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self.locationManager!.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            self.locationManager!.startUpdatingLocation()
        case .denied:
            break
        case .restricted:
            // restricted by e.g. parental controls. User can't enable Location Services
            break
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.presentPermissionErrorMessage()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.myPlace = locations.first
        manager.stopUpdatingLocation()
    }

    func presentPermissionErrorMessage() {
        if self.alertController == nil {
            let title = "位置情報が取得できません"
            let message = "「設定 > プライバシー > 位置情報サービス」よりbeerhuntの位置情報の利用を許可して下さい"
            self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//            let settingAction = UIAlertAction(title: "設定", style: .default, handler: { [unowned self] _ in
//                self.searchTextField.text = ""
//                self.alertController?.dismiss(animated: true, completion: { [unowned self] in
//
//                    if
//                        let url = URL(string: "App-Pefs:root=LOCATION_SERVICES"),
//                        UIApplication.shared.canOpenURL(url)
//                    {
//                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                    }
//                    self.alertController = nil
//                })
//            })
//            self.alertController?.addAction(settingAction)
            let closeAction = UIAlertAction(title: "閉じる", style: .default, handler: { [unowned self] _ in
                self.searchTextField.text = ""
                self.alertController?.dismiss(animated: true, completion: { [unowned self] in
                    self.alertController = nil
                })
            })
            self.alertController?.addAction(closeAction)
        }
        self.present(self.alertController!, animated: true)
    }

}
