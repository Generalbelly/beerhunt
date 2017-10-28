//
//  RestaurantViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/14.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import GooglePlaces
import ImageSlideshow

enum RVSections: Int {
    case info = 0
}

enum RVRows: Int {
    case name = 0
    case phone = 1
    case address = 2
    case website = 3
}

protocol RestaurantViewDelegate: class {
    func didTapFavButton(key: String, isFavorite: Bool) -> ()
}

class RestaurantViewController: UIViewController {
    
    let application = UIApplication.shared
    let defaults = UserDefaults.standard
    var alertController: UIAlertController?
    var placesClient: GMSPlacesClient!
    
    var restaurant: Restaurant!
    var favorites: [String] = []
    
    weak var delegate: RestaurantViewDelegate?
    
    @IBOutlet weak var slideShow: ImageSlideshow!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
    }
    
    @IBOutlet weak var favoriteButton: RoundedButton!
    @IBAction func favoriteButtonTapped(_ sender: Any) {
        self.changeFavButtonColor(isFavorite: !self.restaurant.isFavorite)
        self.delegate?.didTapFavButton(key: self.restaurant.key, isFavorite: self.restaurant.isFavorite)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        placesClient = GMSPlacesClient.shared()
        self.lookupPlaceByID(placeID: restaurant!.placeId)
        
        guard let metadata = restaurant.metadata else { return }
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.picDidTap(_:)))
        self.slideShow.addGestureRecognizer(gestureRecognizer)
        var inputs = [ImageSource]()
        for (index, data) in metadata.enumerated() {
            self.loadImageForMetadata(photoMetadata: data, completion: { [weak self] image in
                guard let strongSelf = self else { return }
                if image != nil {
                    inputs.append(ImageSource(image: image!))
                }
                if index == strongSelf.restaurant.metadata!.count - 1 {
                    strongSelf.slideShow.setImageInputs(inputs)
                }
            })
        }
        self.slideShow.pageControlPosition = .underScrollView
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.favorites = self.defaults.object(forKey: Constants.User.favorites.rawValue) as! [String]
        if self.favorites.contains(restaurant.key) {
            self.restaurant.isFavorite = true
        }
        self.changeFavButtonColor(isFavorite: self.restaurant.isFavorite)
    }
    
    @objc func picDidTap(_ sender: UITapGestureRecognizer) {
        self.slideShow.presentFullScreenController(from: self)
    }
    
    func lookupPlaceByID(placeID: String) {
        placesClient.lookUpPlaceID(placeID, callback: { [weak self] (place, error) -> Void in
            guard let strongSelf = self else { return }
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                print("No place details for \(placeID)")
                return
            }
            
//            print("Place name \(place.name)")
//            print("Place address \(String(describing: place.formattedAddress))")
//            print("Place placeID \(place.placeID)")
//            print("Place attributions \(String(describing: place.attributions))")
            strongSelf.restaurant.address = place.formattedAddress
            strongSelf.restaurant.attributions = place.attributions?.string
            strongSelf.restaurant.phoneNumber = place.phoneNumber?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+81", with: "0")
            strongSelf.restaurant.website = place.website?.absoluteString
            strongSelf.tableView.reloadData()
        })
    }
    
    func changeFavButtonColor(isFavorite: Bool) {
        if isFavorite {
            self.favoriteButton.backgroundColor = UIColor.init(red: 246/255.0, green: 166/255.0, blue: 35/255.0, alpha: 1.0)
            if !self.favorites.contains(self.restaurant.key) {
                self.addToFavorites()
            }
        } else {
            self.favoriteButton.backgroundColor = UIColor.clear
            if self.favorites.contains(self.restaurant.key) {
                self.removeFromFavorites()
            }
        }
        self.restaurant.isFavorite = isFavorite
    }
    
    func addToFavorites() {
        self.favorites = self.favorites + [self.restaurant.key]
        defaults.set(self.favorites, forKey: Constants.User.favorites.rawValue)
    }
    
    func removeFromFavorites() {
        self.favorites = self.favorites.filter { $0 != self.restaurant.key }
        defaults.set(self.favorites, forKey: Constants.User.favorites.rawValue)
    }

}

extension RestaurantViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "info", for: indexPath) as! InfoTableViewCell
        if indexPath.section == RVSections.info.rawValue {
            switch indexPath.row {
            case RVRows.name.rawValue:
                cell.label.text = restaurant.name
                cell.isUserInteractionEnabled = false
                cell.infoImageView.image = UIImage(named: "Restaurant")
            case RVRows.phone.rawValue:
                cell.label?.text = restaurant.phoneNumber
                cell.infoImageView.image = UIImage(named: "Phone")
            case RVRows.address.rawValue:
                cell.label?.text = restaurant.address
                cell.infoImageView.image = UIImage(named: "Pin")
            case RVRows.website.rawValue:
                cell.label?.text = restaurant.website
                cell.infoImageView.image = UIImage(named: "Web")
            default:
                break
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case RVRows.address.rawValue:
            if restaurant.address != nil {
                self.openMapApp(address: restaurant.address!)
            }
        case RVRows.phone.rawValue:
            if restaurant.phoneNumber != nil {
                self.makeCall(number: restaurant.phoneNumber!)
            }
        case RVRows.website.rawValue:
            if restaurant.website != nil {
                self.goToWebsite(url: restaurant.website!)
            }
        default:
            break
        }
    }
    
    func makeCall(number: String) {
        if let url:NSURL = NSURL(string: "tel://\(number)") {
            if application.canOpenURL(url as URL) {
                application.open(url as URL, options: [:], completionHandler: nil)
            }
        }
    }
    
    func openMapApp(address: String) {
        if let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            self.userPickMapApp(encodedAddress: encodedAddress)
        }
    }
    
    func goToWebsite(url: String) {
        if let url = NSURL(string: url) {
            application.open(url as URL, options: [:], completionHandler: nil)
        }
    }
    
    func userPickMapApp(encodedAddress: String){
        if alertController == nil {
            alertController = UIAlertController(title: "お店までの道のりを表示", message: "地図アプリをお選びください", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { [unowned self] _ in
                self.alertController!.dismiss(animated: true, completion: nil)
            }
            if application.canOpenURL(URL(string:"https://www.google.com/maps/")!) {
                let googleAction = UIAlertAction(title: "Google Mapsで開く", style: .default) { [unowned self] _ in
                    let url = NSURL(string: "comgooglemaps://?daddr=\(encodedAddress)")
                    self.application.open(url! as URL, options: [:], completionHandler: nil)
                    self.alertController!.dismiss(animated: true, completion: nil)
                }
                alertController!.addAction(googleAction)
            }
            let appleAction = UIAlertAction(title: "マップで開く", style: .default) { [unowned self] _ in
                let url = NSURL(string: "http://maps.apple.com/?daddr=\(encodedAddress)")
                self.application.open(url! as URL, options: [:], completionHandler: nil)
                self.alertController!.dismiss(animated: true, completion: nil)
            }
            alertController!.addAction(cancelAction)
            alertController!.addAction(appleAction)
        }
        self.present(alertController!, animated: true, completion: nil)
    }
    
    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata, completion: @escaping (_ image: UIImage?) -> Void) {
        placesClient.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
                return completion(nil)
            } else {
                return completion(photo)
            }
        })
    }

}
