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
import CoreLocation
import DZNEmptyDataSet

class ResultViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.emptyDataSetSource = self
            tableView.emptyDataSetDelegate = self
            tableView.tableFooterView = UIView()
        }
    }
    
    var ref: DatabaseReference!
    var restaurants = [Restaurant]()
    var station: Station?
    var myPlace: CLLocation?
    var placesClient: GMSPlacesClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        if station != nil {
            self.ref.child("locations").child(station!.key).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard let strongSelf = self else { return }
                if snapshot.value != nil {
                    strongSelf.restaurants = (snapshot.children.allObjects as! [DataSnapshot]).map{ (item) -> Restaurant in
                        var data = item.value as! [String: Any]
                        data["key"] = item.key
                        return Restaurant(data: data)
                    }
                    strongSelf.tableView.reloadData()
                }
            })
        } else if myPlace != nil {
            // One degree of latitude and of longtitude is approximately 111 kilometers
            let latitudeDelta = Double(3.0 / 111.0 * 0.5)
            let longitudeDelta = Double(3.0 / 111.0 * 0.5)
            fetchNearbyPlaces(minLat: myPlace!.coordinate.latitude - latitudeDelta, maxLat: myPlace!.coordinate.latitude + latitudeDelta, minLon: myPlace!.coordinate.longitude - longitudeDelta, maxLon: myPlace!.coordinate.longitude + longitudeDelta)
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
    
    func fetchNearbyPlaces(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        ref.child("restaurants").queryOrdered(byChild: "lat").queryStarting(atValue: minLat).queryEnding(atValue: maxLat).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            if snapshot.value != nil {
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    var data = item.value as! [String: Any]
                    if let lon = data["lon"] as? Double, let lat = data["lat"] as? Double {
                        if lon > minLon && lon < maxLon {
                            data["key"] = item.key
                            data["distance"] = Int(strongSelf.myPlace!.distance(from: CLLocation(latitude: lat, longitude: lon)))
                            
                            let restaurant = Restaurant(data: data)
                            strongSelf.restaurants.append(restaurant)
                        }
                    }
                }
                strongSelf.tableView.reloadData()
            }
        }) { (error) in
            print(error.localizedDescription)
        }
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
        cell.subLabel!.text = (self.station != nil) ? restaurant.travelTime : "徒歩\(restaurant.distance! / 80)分"
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.placesClient.lookUpPhotos(forPlaceID: restaurant.placeId) { (photos, error) -> Void in
                if let error = error {
                    // TODO: handle the error.
                    print("Error: \(error.localizedDescription)")
                } else {
                    restaurant.metadata = photos!.results
                    if let firstPhoto = photos?.results.first {
                        DispatchQueue.main.async {
                            cell.activityIndicator.startAnimating()
                            cell.activityIndicator.show()
                            cell.backgroundImageView.image = nil
                            strongSelf.loadImageForMetadata(photoMetadata: firstPhoto) { photo in
                                cell.activityIndicator.stopAnimating()
                                cell.activityIndicator.hide()
                                cell.backgroundImageView.image = photo
                            }
                        }
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

extension ResultViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = "周辺にレストランはありません"
        let attributes = [
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18),
            NSAttributedStringKey.foregroundColor: UIColor.darkGray,
            ]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -(self.navigationController!.navigationBar.frame.size.height) / 2.0
    }
    
}
