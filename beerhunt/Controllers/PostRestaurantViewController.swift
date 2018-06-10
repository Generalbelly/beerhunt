//
//  FormViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/12.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Firebase
import GooglePlaces

class PostRestaurantViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.delegate = self
            self.tableView.dataSource = self
        }
    }

    var image: UIImage!
    var restaurants: [Restaurant]?
    var ref: DatabaseReference?
    var storageRef: StorageReference?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = self.image
        self.storageRef = Storage.storage().reference()
//        self.ref = Database.database().reference()
//        self.ref!.child("restaurants").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
//            guard let strongSelf = self else { return }
//            for child in snapshot.children {
//                if
//                    let snapshot = child as? DataSnapshot,
//                    let restaurant = Restaurant(snapshot: snapshot)
//                {
//                    if strongSelf.restaurants == nil {
//                        strongSelf.restaurants = [Restaurant]()
//                    } else {
//                        strongSelf.restaurants!.append(restaurant)
//                    }
//                }
//            }
//            guard
//                let restaurants = strongSelf.restaurants,
//                restaurants.count > 0,
//                let row: SearchPushRow<SearchItemModel> = strongSelf.form.rowBy(tag: "restaurantName")
//            else { return }
//            row.options = ([Restaurant(name: "新規追加", key: "add_new")] + restaurants).map { restaurant -> SearchItemModel in
//                return SearchItemModel.init(restaurant.key!, restaurant.name)
//            }
//            row.updateCell()
//        })

//        self.form +++ Section { [weak self] section in
//                guard let strongSelf = self else { return }
//                section.header = {
//                    let width = strongSelf.view.frame.width
//                    let height = width
//                    var header = HeaderFooterView<UIView>(.callback({
//                        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
//                        let imageView = UIImageView(image: strongSelf.image)
//                        imageView.contentMode = .scaleAspectFit
//                        imageView.frame = view.frame
//                        view.addSubview(imageView)
//                        view.clipsToBounds = true
//                        return view
//                    }))
//                    header.height = { height }
//                    return header
//                }()
//            }
//            <<< SearchPushRow<SearchItemModel>("restaurantName") { row in
//                row.title = "レストラン名"
//            }.onChange { [weak self] row in
//                if
//                    let value = row.value,
//                    value.id == "add_new",
//                    let strongSelf = self,
//                    let arvc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "addNewRestaurantViewController") as? AddNewRestaurantViewController
//                {
//                    strongSelf.show(arvc, sender: nil)
//                }
//            }
//            <<< TextAreaRow("comment") { row in
//                row.placeholder = "コメント（オプション）"
//                row.textAreaHeight = .dynamic(initialTextViewHeight: 110)
//            }
//            <<< ButtonRow { row in
//                row.title = "投稿する"
//            }.cellSetup { cell, _ in
//                cell.backgroundColor = UIColor.darkGray
//                cell.tintColor = UIColor.white
//            }.onCellSelection { [weak self] _, _ in
//                guard let strongSelf = self else { return }
//                strongSelf.submit()
//            }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        self.restaurants = nil
        self.ref = nil
        self.storageRef = nil
    }

    func submit() {
        if let user = Auth.auth().currentUser {
            guard let storageRef = self.storageRef else { return }
            guard let data = UIImagePNGRepresentation(self.image) else { return }
            let fileKey = UUID().uuidString
            let filePath = "\(user.uid)/\(fileKey)"
            storageRef.child(filePath).putData(data, metadata: nil, completion: { (_, _) in
//                guard let metadata = metadata else { return }
                storageRef.downloadURL { [weak self] (url, _) in
                    guard
                        let downloadURL = url,
                        let strongSelf = self,
                        let ref = strongSelf.ref
                    else { return }
                    ref.child("users").child(user.uid).updateChildValues([fileKey: downloadURL])
                }
            })
        } else {
            // No user is signed in.
            // ...
        }
    }
}

extension PostRestaurantViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "field", for: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
