//
//  ViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/05.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import FirebaseDatabase
import CoreLocation

class SearchViewController: UIViewController {

    @IBAction func nearMeButton(_ sender: Any) {
        requestLocation()
    }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    let searchController = UISearchController(searchResultsController: nil)
    var alertController: UIAlertController! {
        didSet {
            let OKAction = UIAlertAction(title: "閉じる", style: .default, handler: { [unowned self] _ in
                self.alertController.dismiss(animated: true, completion: nil)
            })
            self.alertController.addAction(OKAction)
        }
    }
    
    var locationManager: CLLocationManager?
    
    var ref: DatabaseReference!
    var stations = [Station]()
    var filteredStations = [Station]()
    var isFetching = false
    var myPlace: CLLocation?
    
    var selectedStation: Station?
    var restaurants = [Restaurant]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let title = "位置情報が取得できません"
        let message = "「設定 > プrライバシー > 位置情報サービス」よりbeerhuntの位置情報の利用を許可して下さい"
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        ref = Database.database().reference()
        ref.child("stations").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            if snapshot.value != nil {
                strongSelf.stations = (snapshot.children.allObjects as! [DataSnapshot]).map{ (item) -> Station in
                    var data = item.value as! [String: String]
                    data["key"] = item.key
                    return Station(data: data)
                }
                strongSelf.tableView.reloadData()
            }
        })
    }

    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredStations = stations.filter({(station : Station) -> Bool in
            return station.name.contains(searchText) || station.furigana.contains(searchText)
        })
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let rvc = segue.destination as! ResultViewController
        if segue.identifier == "result" {
            rvc.station = self.selectedStation
        } else if segue.identifier == "nearme" {
            rvc.myPlace = self.myPlace
        }
    }
}

extension SearchViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredStations.count
        }
        return stations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "station", for: indexPath)
        let station: Station
        if isFiltering() {
            station = filteredStations[indexPath.row]
        } else {
            station = stations[indexPath.row]
        }
        cell.textLabel!.text = station.name
        cell.detailTextLabel!.text = station.line
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isFiltering() {
            selectedStation = filteredStations[indexPath.row]
        } else {
            selectedStation = stations[indexPath.row]
        }
        performSegue(withIdentifier: "result", sender: self)
    }
    
}

extension SearchViewController: CLLocationManagerDelegate {
    
    func requestLocation() {
        if locationManager == nil {
            locationManager = CLLocationManager()
        }
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.delegate = self
        locationManager!.requestWhenInUseAuthorization()
        locationManager!.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager!.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            locationManager!.startUpdatingLocation()
            break
        case .denied:
            if self.alertController.isBeingPresented {
                self.alertController.dismiss(animated: true, completion: nil)
            }
            self.present(alertController, animated: true)
            break
        case .restricted:
            // restricted by e.g. parental controls. User can't enable Location Services
            break
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            if !isFetching {
                myPlace = location
                isFetching = true
                performSegue(withIdentifier: "nearme", sender: self)
            }
        }
        manager.stopUpdatingLocation()
    }
    
}
