//
//  FavoriteViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/10/27.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Firebase
import GooglePlaces
import CoreLocation
import DZNEmptyDataSet

class FavoritesViewController: UIViewController {

    let defaults = UserDefaults.standard

    var placesClient: PlacesClient!

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
        self.placesClient = PlacesClient()
        self.ref = Database.database().reference()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let savedFavorites = self.defaults.object(forKey: Constants.User.favorites.rawValue) as? [String] {
            self.favorites = savedFavorites
        }
        for (index, restaurant) in self.restaurants.enumerated() {
            if !self.favorites.contains(restaurant.key!) {
                self.restaurants.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath(item: index, section: 0)], with: UITableViewRowAnimation.automatic)
            }
        }
        for favorite in self.favorites {
            if !self.restaurants.contains { $0.key == favorite } {
                self.fetchFavoriteRestaurant(key: favorite)
            }
        }
    }

    func fetchFavoriteRestaurant(key: String) {
        self.ref.child("restaurants/\(key)").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            if let restaurant = Restaurant(snapshot: snapshot) {
                strongSelf.restaurants.append(restaurant)
            }
            if strongSelf.restaurants.count > 0 {
                strongSelf.tableView.reloadData()
            }
        })
    }

}

extension FavoritesViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.restaurants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "favorite", for: indexPath) as? RestaurantTableViewCell else { assert(false, "error occured in favoriteTableView") }
        let restaurant = self.restaurants[indexPath.row]
        cell.mainLabel!.text = restaurant.name
        cell.subLabel!.text = ""
        if let placeId = restaurant.placeId {
            self.placesClient.lookUpPhotos(placeId: placeId) { [weak self]  photos in
                if let photos = photos {
                    restaurant.metadata = photos.results
                    if let firstPhoto = photos.results.first {
                        cell.activityIndicator.startAnimating()
                        cell.activityIndicator.show()
                        cell.backgroundImageView.image = nil
                        guard let strongSelf = self else { return }
                        strongSelf.placesClient.loadImageForMetadata(photoMetadata: firstPhoto) { photo in
                            cell.activityIndicator.stopAnimating()
                            cell.activityIndicator.hide()
                            cell.backgroundImageView.image = photo
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
        guard let rvc = self.storyboard?.instantiateViewController(withIdentifier: "restaurantViewController") as? RestaurantViewController else { return }
        rvc.restaurant = self.restaurants[indexPath.row]
        rvc.delegate = self
        navigationController?.pushViewController(rvc, animated: true)
    }

}

extension FavoritesViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let string = "まだお気に入りに登録されたお店はありません"
        let attributes = [
            NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body),
            NSAttributedStringKey.foregroundColor: UIColor.darkGray
            ] as [NSAttributedStringKey: Any]
        return NSAttributedString(string: string, attributes: attributes)
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -(self.navigationController!.navigationBar.frame.size.height) / 2.0
    }

}

extension FavoritesViewController: RestaurantViewDelegate {
    func didTapFavButton(key: String, isFavorite: Bool) {
        if !isFavorite {
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
