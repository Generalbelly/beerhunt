//
//  ViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/05.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Firebase
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
    var placesClient: PlacesClient!

    override func viewDidLoad() {
        self.placesClient = PlacesClient()
        super.viewDidLoad()
        self.ref = Database.database().reference()
        if let station = self.station {
            self.ref.child("locations").child(station.key!).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                if snapshot.value != nil {
                    guard let strongSelf = self else { return }
                    for child in snapshot.children {
                        if
                            let snapshot = child as? DataSnapshot,
                            let restaurant = Restaurant(snapshot: snapshot)
                        {
                            strongSelf.restaurants.append(restaurant)
                            guard let placeId = restaurant.placeId else { return }
                            DispatchQueue.global(qos: .default).async {
                                strongSelf.placesClient.fetchGooglePlaceInfo(placeId: placeId) { place in
                                    guard let place = place else { return }
                                    restaurant.address = place.formattedAddress
                                    restaurant.attributions = place.attributions?.string
                                    restaurant.phoneNumber = place.phoneNumber?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+81", with: "0")
                                    restaurant.website = place.website?.absoluteString
                                }
                            }
                        }
                    }
                    strongSelf.tableView.reloadData()
                }
            })
        } else if myPlace != nil {
            // One degree of latitude and of longtitude is approximately 111 kilometers
            let latitudeDelta = Double(3.0 / 111.0 * 0.5)
            let longitudeDelta = Double(3.0 / 111.0 * 0.5)
            self.fetchNearbyPlaces(
                minLat: myPlace!.coordinate.latitude - latitudeDelta,
                maxLat: myPlace!.coordinate.latitude + latitudeDelta,
                minLon: myPlace!.coordinate.longitude - longitudeDelta,
                maxLon: myPlace!.coordinate.longitude + longitudeDelta
            )
        }
    }

    func fetchNearbyPlaces(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        self.ref.child("restaurants").queryOrdered(byChild: "lat").queryStarting(atValue: minLat).queryEnding(atValue: maxLat).observeSingleEvent(
            of: .value,
            with: { [weak self] (snapshot) in
                guard let strongSelf = self else { return }
                for child in snapshot.children {
                    if
                        let snapshot = child as? DataSnapshot,
                        let restaurant = Restaurant(snapshot: snapshot),
                        restaurant.lon > minLon && restaurant.lon < maxLon
                    {
                        restaurant.distance = Int(strongSelf.myPlace!.distance(from: CLLocation(latitude: restaurant.lat, longitude: restaurant.lon)))
                        strongSelf.restaurants.append(restaurant)
                    }
                }
                strongSelf.tableView.reloadData()
            },
            withCancel: { (error) in
                print(error.localizedDescription)
            }
        )
    }

}

extension ResultViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "restaurant", for: indexPath) as? RestaurantTableViewCell else {
            assert(false)
        }
        let restaurant = restaurants[indexPath.row]
        cell.mainLabel!.text = restaurant.name
        cell.subLabel!.text = (self.station != nil) ? restaurant.travelTime : "徒歩\(restaurant.distance! / 80)分"
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard
                let strongSelf = self,
                let placeId = restaurant.placeId
            else { return }
            strongSelf.placesClient.lookUpPhotos(placeId: placeId) { [weak self] photos -> Void in
                guard let strongSelf = self else { return }
                if let photos = photos {
                    restaurant.metadata = photos.results
                    if let firstPhoto = photos.results.first {
                        DispatchQueue.main.async {
                            cell.activityIndicator.startAnimating()
                            cell.activityIndicator.show()
                            DispatchQueue.global(qos: .userInteractive).async {
                                strongSelf.placesClient.loadImageForMetadata(photoMetadata: firstPhoto) { photo in
                                    DispatchQueue.main.async {
                                        cell.activityIndicator.stopAnimating()
                                        cell.activityIndicator.hide()
                                        cell.backgroundImageView.image = photo
                                    }
                                }
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
        guard let rvc = storyboard?.instantiateViewController(withIdentifier: "restaurantViewController") as? RestaurantViewController else { assert(false) }
        rvc.restaurant = restaurants[indexPath.row]
        navigationController?.pushViewController(rvc, animated: true)
    }

}

extension ResultViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = "周辺にレストランはありません"
        let attributes = [
            NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body),
            NSAttributedStringKey.foregroundColor: UIColor.darkGray
        ]
        return NSAttributedString(string: string, attributes: attributes)
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -(self.navigationController!.navigationBar.frame.size.height) / 2.0
    }

}
