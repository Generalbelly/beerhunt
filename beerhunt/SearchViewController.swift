//
//  ViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/05.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseDatabase

class SearchViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    let searchController = UISearchController(searchResultsController: nil)
    
    var locationManager = CLLocationManager()
    
    var ref: DatabaseReference!
    var stations = [Station]()
    var filteredStations = [Station]()
    var isFetching = false
    
    var selectedStation: Station?
    var restaurants = [Restaurant]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        ref = Database.database().reference()
        ref.child("stations").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                self.stations = (snapshot.children.allObjects as! [DataSnapshot]).map{ (item) -> Station in
                    var data = item.value as! [String: String]
                    data["key"] = item.key
                    return Station(data: data)
                }
                self.tableView.reloadData()
            }
        })
//        requestLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.startUpdatingLocation()
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
        rvc.station = self.selectedStation
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
        selectedStation = stations[indexPath.row]
        performSegue(withIdentifier: "result", sender: self)
    }
    
}

extension SearchViewController: CLLocationManagerDelegate {
    
    func requestLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("ユーザーはこのアプリケーションに関してまだ選択を行っていません")
            // 許可を求めるコードを記述する（後述）
            break
        case .denied:
            print("ローケーションサービスの設定が「無効」になっています (ユーザーによって、明示的に拒否されています）")
            // 「設定 > プライバシー > 位置情報サービス で、位置情報サービスの利用を許可して下さい」を表示する
            break
        case .restricted:
            print("このアプリケーションは位置情報サービスを使用できません(ユーザによって拒否されたわけではありません)")
            // 「このアプリは、位置情報を取得できないために、正常に動作できません」を表示する
            break
        case .authorizedWhenInUse:
            print("起動時のみ、位置情報の取得が許可されています。")
            locationManager.startUpdatingLocation()
            break
        default:
            break
        }
    }
    
    func fetchNearbyPlaces(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        ref.child("restaurants").queryOrdered(byChild: "lat").queryStarting(atValue: minLat).queryEnding(atValue: maxLat).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                for item in snapshot.children.allObjects as! [DataSnapshot] {
                    let data = item.value as! [String: Double]
                    if data["lon"]! > minLon && data["lon"]! < maxLon {
                        self.ref.child("restaurants").child(item.key).observeSingleEvent(of: .value, with: { (snapshot) in
                            var data2 = snapshot.value as! [String: Any]
                            data2["key"] = item.key
                            let restaurant = Restaurant(data: data2)
                            self.restaurants.append(restaurant)
                        })
                    }
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            // One degree of latitude and of longtitude is approximately 111 kilometers
            if !isFetching {
                let center = location.coordinate
                let latitudeDelta = Double(2.0 / 111.0 * 0.5)
                let longitudeDelta = Double(2.0 / 111.0 * 0.5)
                
                fetchNearbyPlaces(minLat: center.latitude - latitudeDelta, maxLat: center.latitude + latitudeDelta, minLon: center.longitude - longitudeDelta, maxLon: center.longitude + longitudeDelta)
                isFetching = true
            }
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,didFailWithError error: Error){
        print("come")
    }
    
}
