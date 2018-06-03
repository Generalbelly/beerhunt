//
//  FormViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/12.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Firebase
import Eureka

class PostRestaurantViewController: FormViewController {

    var image: UIImage!
    var restaurants: [Restaurant]?
    var ref: DatabaseReference?
    var storageRef: StorageReference?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.storageRef = Storage.storage().reference()
        self.ref = Database.database().reference()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.ref!.child("restaurants").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard let strongSelf = self else { return }
                for child in snapshot.children {
                    if
                        let snapshot = child as? DataSnapshot,
                        let restaurant = Restaurant(snapshot: snapshot)
                    {
                        if strongSelf.restaurants == nil {
                            strongSelf.restaurants = [Restaurant]()
                        } else {
                            strongSelf.restaurants!.append(restaurant)
                        }
                    }
                }
                DispatchQueue.main.async { [weak self] in
                    guard
                        let strongSelf = self,
                        let restaurants = strongSelf.restaurants,
                        restaurants.count > 0
                    else { return }
                    guard let row: SearchPushRow<SearchItemModel> = strongSelf.form.rowBy(tag: "restaurantName") else { return }
                    row.options = restaurants.map { restaurant -> SearchItemModel in
                        return SearchItemModel.init(restaurant.key!, restaurant.name)
                    }
                    row.updateCell()
                }
            })
        }
        form +++ Section { [weak self] section in
                guard let strongSelf = self else { return }
                section.header = {
                    let width = strongSelf.view.frame.width
                    let height = width
                    var header = HeaderFooterView<UIView>(.callback({
                        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
                        let imageView = UIImageView(image: strongSelf.image)
                        imageView.contentMode = .scaleAspectFit
                        imageView.frame = view.frame
                        view.addSubview(imageView)
                        view.clipsToBounds = true
                        return view
                    }))
                    header.height = { height }
                    return header
                }()
            }
            <<< SearchPushRow<SearchItemModel>("restaurantName") { row in
                row.title = "レストラン名"
            }
            <<< TextAreaRow("comment") { row in
                row.placeholder = "コメント（オプション）"
                row.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            }
            <<< ButtonRow { row in
                row.title = "投稿する"
            }.cellSetup { cell, _ in
                cell.backgroundColor = UIColor.darkGray
                cell.tintColor = UIColor.white
            }.onCellSelection { [weak self] _, _ in
                guard let strongSelf = self else { return }
                strongSelf.submit()
            }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view will appear")
    }

    deinit {
        self.restaurants = nil
        self.ref = nil
        self.storageRef = nil
    }

//    @objc func pictureTapped(recognizer: UITapGestureRecognizer) {
//
//    }

    func submit() {

        if let user = Auth.auth().currentUser {
            guard let storageRef = self.storageRef else { return }
            guard let data = UIImagePNGRepresentation(self.image) else { return }
            let fileKey = UUID().uuidString
            let filePath = "\(user.uid)/\(fileKey)"
            storageRef.child(filePath).putData(data, metadata: nil, completion: { (metadata, _) in
                guard let metadata = metadata else { return }

                let size = metadata.size
                print(size)
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
