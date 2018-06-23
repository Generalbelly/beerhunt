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
import Eureka

class NewPostViewController: FormViewController {

    var image: UIImage!
    var restaurants: [Restaurant]?
    var ref: DatabaseReference?
    var storageRef: StorageReference?
    var alertController: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.storageRef = Storage.storage().reference()
        self.ref = Database.database().reference()
        self.ref!.child("restaurants").observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
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
            guard
                let restaurants = strongSelf.restaurants,
                restaurants.count > 0,
                let row: SearchPushRow<SearchItemModel> = strongSelf.form.rowBy(tag: "restaurantName")
            else { return }
            row.options = restaurants.map { restaurant -> SearchItemModel in
                return SearchItemModel.init(restaurant.key!, restaurant.name)
            }
            row.updateCell()
        })

        self.form +++ Section { [weak self] section in
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
//            <<< PushRow<String>("restaurantName") { row in
//                row.title = "レストラン名"
//                row.presentationMode = .segueName(segueName: "selectRestaurant", onDismiss: nil)
//            }
            <<< SearchPushRow<SearchItemModel>("restaurantName") { row in
                row.title = "レストラン名"
            }
            <<< TextAreaRow("body") { row in
                row.placeholder = "コメント（任意）"
                row.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            }
            <<< ButtonRow { row in
                row.title = "投稿する"
            }.cellSetup { cell, _ in
                cell.backgroundColor = UIColor.darkGray
                cell.tintColor = UIColor.white
            }.onCellSelection { [weak self] _, _ in
                guard let strongSelf = self else { return }
                guard
                    let restaurantNameRow = strongSelf.form.rowBy(tag: "restaurantName") as? SearchPushRow<SearchItemModel>,
                    let _ = restaurantNameRow.value?.id
                else {
                    strongSelf.showAlertVC(title: "入力内容に不備があります", message: "レストラン名は必須項目です")
                    return
                }
                strongSelf.submit()
            }
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
            guard
                let restaurantNameRow = self.form.rowBy(tag: "restaurantName") as? SearchPushRow<SearchItemModel>,
                let restaurantKey = restaurantNameRow.value?.id
            else { return }

            guard let storageRef = self.storageRef else { return }
            guard let data = UIImagePNGRepresentation(self.image) else { return }
            let fileKey = UUID().uuidString
            let imagePath = "images/\(fileKey)"
            let imageRef = storageRef.child(imagePath)
            let uploadTask = imageRef.putData(data, metadata: nil) { [weak self] (metadata, _) in
                guard let metadata = metadata else {
                    return
                }
                guard
                    let strongSelf = self,
                    let storageRef = strongSelf.storageRef
                else { return }
//                FIRStorageMetadata 0x604000b2a460: {
//                    bucket = "beerhunt-staging.appspot.com";
//                    contentDisposition = "inline; filename*=utf-8''DBF5753D-8F68-4F7F-8799-8D2801DF3097";
//                    contentEncoding = identity;
//                    contentType = "application/octet-stream";
//                    generation = 1529246831270365;
//                    md5Hash = "+bYFOnO0e9HW+D/jyfGF2Q==";
//                    metageneration = 1;
//                    name = "6ZJtrJL8T9YZ49L4ANHdlRh8WIs2/DBF5753D-8F68-4F7F-8799-8D2801DF3097";
//                    size = 4038508;
//                    timeCreated = "2018-06-17T14:47:11.270Z";
//                    updated = "2018-06-17T14:47:11.270Z";
//                }
                storageRef.child(imagePath).downloadURL { [weak self] (url, _) in
                    guard
                        let downloadURL = url,
                        let strongSelf = self,
                        let ref = strongSelf.ref
                    else { return }
                    let post = Post(
                        key: ref.child("posts").childByAutoId().key,
                        photo: downloadURL.absoluteString,
                        userId: user.uid,
                        author: user.displayName ?? "",
                        restaurantKey: restaurantKey
                    )
                    if
                        let bodyRow = self?.form.rowBy(tag: "body") as? TextAreaRow,
                        let bodyValue = bodyRow.value
                    {
                        post.body = bodyValue
                    }

                    var postData = post.toAnyObject()
                    postData["created_at"] = ServerValue.timestamp()
                    postData["updated_at"] = ServerValue.timestamp()
                    ref.updateChildValues([
                        "posts/\(post.key!)": postData,
                        "user-posts/\(user.uid)/\(post.key!)": postData,
                        "restaurant-posts/\(restaurantKey)/\(post.key!)": postData
                    ])
                }
            }
        } else {
            // No user is signed in.
            // ...
        }
    }

    func showAlertVC(title: String, message: String) {
        if self.alertController == nil {
            self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        } else {
            self.alertController!.title = title
            self.alertController!.message = message
        }
        if self.alertController!.actions.count == 0 {
            let completeAction = UIAlertAction(title: "閉じる", style: .default) { [unowned self] _ in
                self.alertController!.dismiss(animated: true, completion: { [unowned self] in
                    self.alertController = nil
                })
            }
            self.alertController!.addAction(completeAction)
        }
        self.present(self.alertController!, animated: true)
    }

}
