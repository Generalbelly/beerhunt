//
//  SelectRestaurantViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/06/10.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Firebase
import GooglePlaces

class SelectRestaurantViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.dataSource = self
            self.tableView.delegate = self
        }
    }

    let searchController = UISearchController(searchResultsController: nil)

    var ref: DatabaseReference!
    var restaurants = [Restaurant]()
    var filteredRestaurants = [Restaurant]()
    var selectedRestaurant: Restaurant?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.definesPresentationContext = true
        self.tableView.tableHeaderView = searchController.searchBar

        self.ref = Database.database().reference()
        self.ref.child("restaurants").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            for child in snapshot.children {
                if
                    let snapshot = child as? DataSnapshot,
                    let restaurant = Restaurant(snapshot: snapshot)
                {
                    strongSelf.restaurants.append(restaurant)
                }
            }
            strongSelf.tableView.reloadData()
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredRestaurants = restaurants.filter({(restaurant: Restaurant) -> Bool in
            return restaurant.name.contains(searchText)
        })
        tableView.reloadData()
    }
}

extension SelectRestaurantViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }

    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

}

extension SelectRestaurantViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredRestaurants.count
        }
        return restaurants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "restaurant", for: indexPath)
        cell.selectionStyle = .none
        let restaurant: Restaurant
        if isFiltering() {
            restaurant = filteredRestaurants[indexPath.row]
        } else {
            restaurant = restaurants[indexPath.row]
        }
        cell.textLabel!.text = restaurant.name
        if restaurant.name == self.selectedRestaurant?.name {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let oldIndex = tableView.indexPathForSelectedRow {
            tableView.cellForRow(at: oldIndex)?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFiltering() {
            selectedRestaurant = filteredRestaurants[indexPath.row]
        } else {
            selectedRestaurant = restaurants[indexPath.row]
        }
    }

}

extension SelectRestaurantViewController: GMSAutocompleteViewControllerDelegate {

    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        dismiss(animated: true, completion: nil)
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }

    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

}
