//
//  ViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/05.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GooglePlaces

class ResultViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    var ref: DatabaseReference!
    var restaurants = [Restaurant]()
    var station: Station?
    var placesClient: GMSPlacesClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        if station != nil {
            self.ref.child("locations").child(station!.key).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.value != nil {
                    self.restaurants = (snapshot.children.allObjects as! [DataSnapshot]).map{ (item) -> Restaurant in
                        var data = item.value as! [String: Any]
                        data["key"] = item.key
                        return Restaurant(data: data)
                    }
                    self.tableView.reloadData()
                }
            })
        }
        placesClient = GMSPlacesClient.shared()
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

extension ResultViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "restaurant", for: indexPath) as! RestaurantTableViewCell
        let restaurant = restaurants[indexPath.row]
        cell.mainLabel!.text = restaurant.name
        cell.subLabel!.text = restaurant.travelTime
        
        placesClient.lookUpPhotos(forPlaceID: restaurant.placeId) { (photos, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
            } else {
                restaurant.metadata = photos!.results
                if let firstPhoto = photos?.results.first {
                    self.loadImageForMetadata(photoMetadata: firstPhoto) { photo in
                        cell.coverView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                        cell.backgroundImageView.image = photo
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rvc = storyboard?.instantiateViewController(withIdentifier: "restaurantViewController") as! RestaurantViewController
        rvc.restaurant = restaurants[indexPath.row]
        navigationController?.pushViewController(rvc, animated: true)
    }
}

