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

class RestaurantViewController: UIViewController {

    @IBOutlet weak var slideShow: ImageSlideshow!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    var alertController: UIAlertController?
    
    var placesClient: GMSPlacesClient!

    var restaurant: Restaurant!
    let application = UIApplication.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesClient = GMSPlacesClient.shared()
        self.lookupPlaceByID(placeID: restaurant!.placeId)
        
        guard let metadata = restaurant.metadata else { return }
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.picDidTap(_:)))
        slideShow.addGestureRecognizer(gestureRecognizer)
        var inputs = [ImageSource]()
        for (index, data) in metadata.enumerated() {
            self.loadImageForMetadata(photoMetadata: data, completion: { image in
                if image != nil {
                    inputs.append(ImageSource(image: image!))
                }
                if index == self.restaurant.metadata!.count - 1 {
                    self.slideShow.setImageInputs(inputs)
                }
            })
        }
        slideShow.pageControlPosition = .insideScrollView
    }
    
    func picDidTap(_ sender: UITapGestureRecognizer) {
        slideShow.presentFullScreenController(from: self)
    }
    
    func lookupPlaceByID(placeID: String) {
        print(placeID)
        placesClient.lookUpPlaceID(placeID, callback: { (place, error) -> Void in
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                print("No place details for \(placeID)")
                return
            }
            
            print("Place name \(place.name)")
            print("Place address \(String(describing: place.formattedAddress))")
            print("Place placeID \(place.placeID)")
            print("Place attributions \(String(describing: place.attributions))")
            self.restaurant.address = place.formattedAddress
            self.restaurant.attributions = place.attributions?.string
            self.restaurant.phoneNumber = place.phoneNumber
            self.restaurant.website = place.website?.absoluteString
            self.tableView.reloadData()
        })
    }

}

extension RestaurantViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        if indexPath.section == RVSections.info.rawValue {
            switch indexPath.row {
            case RVRows.name.rawValue:
                cell.textLabel?.text = restaurant.name
                cell.isUserInteractionEnabled = false
            case RVRows.phone.rawValue:
                cell.textLabel?.text = restaurant.phoneNumber
            case RVRows.address.rawValue:
                cell.textLabel?.text = restaurant.address
            case RVRows.website.rawValue:
                cell.textLabel?.text = restaurant.website
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == RVSections.info.rawValue {
            if indexPath.row == RVRows.address.rawValue {
                return (restaurant.address != nil ) ? 100 : 0
            }
            if indexPath.row == RVRows.phone.rawValue {
                return (restaurant.phoneNumber != nil ) ? 44 : 0
            }
            if indexPath.row == RVRows.website.rawValue {
                return (restaurant.website != nil ) ? 44 : 0
            }
        }
        return 44
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
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { _ in
                self.alertController!.dismiss(animated: true, completion: nil)
            }
            if application.canOpenURL(NSURL(string:"comgooglemaps://")! as URL) {
                let googleAction = UIAlertAction(title: "Google Mapsで開く", style: .default) { _ in
                    let url = NSURL(string: "comgooglemaps://?daddr=\(encodedAddress)")
                    self.application.open(url! as URL, options: [:], completionHandler: nil)
                    self.alertController!.dismiss(animated: true, completion: nil)
                }
                alertController!.addAction(googleAction)
            }
            let appleAction = UIAlertAction(title: "マップで開く", style: .default) { _ in
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
