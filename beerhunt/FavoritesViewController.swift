//
//  FavoriteViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/10/27.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GooglePlaces
import CoreLocation
import DZNEmptyDataSet

class FavoritesViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    var placesClient: GMSPlacesClient!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.emptyDataSetSource = self
            self.tableView.emptyDataSetDelegate = self
            self.tableView.tableFooterView = UIView()
        }
    }
    
    var favorites: [String] = []
    var ref: DatabaseReference!
    var restaurants = [Restaurant]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        self.placesClient = GMSPlacesClient.shared()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.favorites = self.defaults.object(forKey: Constants.User.favorites.rawValue) as! [String]
        if self.favorites.count > self.restaurants.count {
            for favorite in self.favorites {
                self.fetchFavoriteRestaurant(key: favorite)
            }
        }
    }
    
    func fetchFavoriteRestaurant(key: String) {
        self.ref.child("restaurants/\(key)").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            if let item = snapshot.value as? [String: Any] {
                var data = item
                data["key"] = key
                let restaurant = Restaurant(data: data)
                strongSelf.restaurants.append(restaurant)
                strongSelf.tableView.insertRows(at: [IndexPath(item: strongSelf.restaurants.count - 1, section: 0)], with: UITableViewRowAnimation.automatic)
                if strongSelf.restaurants.count == 1 {
                    strongSelf.tableView.reloadEmptyDataSet()
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata, completion: @escaping (_ image: UIImage?) -> Void) {
        self.placesClient.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
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

extension FavoritesViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.restaurants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favorite", for: indexPath) as! RestaurantTableViewCell
        let restaurant = self.restaurants[indexPath.row]
        cell.mainLabel!.text = restaurant.name
        cell.subLabel!.text = ""
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
        rvc.restaurant = self.restaurants[indexPath.row]
        rvc.delegate = self
        navigationController?.pushViewController(rvc, animated: true)
    }
    
}

extension FavoritesViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = "まだお気に入りに登録されたお店はありません"
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

extension FavoritesViewController: RestaurantViewDelegate {
    func didTapFavButton(key: String, isFavorite: Bool) {
        if (!isFavorite) {
            let index = self.restaurants.index { $0.key == key }
            if index != nil {
                self.restaurants.remove(at: index!)
                self.tableView.deleteRows(at: [IndexPath(item: index!, section: 0)], with: UITableViewRowAnimation.automatic)
                if self.restaurants.count == 0 {
                    self.tableView.reloadEmptyDataSet()
                }
            }
        }
    }
}
