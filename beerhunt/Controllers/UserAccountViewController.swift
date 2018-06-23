//
//  UserAccountViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/06/16.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Kingfisher
import DZNEmptyDataSet

class UserAccountViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.emptyDataSetSource = self
            self.collectionView.emptyDataSetDelegate = self
        }
    }

    var posts = [Post]()

    var ref: DatabaseReference!
    var handler: AuthStateDidChangeListenerHandle?
    var emptyMessage = "ログインすると投稿した写真が表示されます"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        handler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                guard let strongSelf = self else { return }
                if strongSelf.posts.count == 0 {
                    strongSelf.emptyMessage = "まだ投稿がありません"
                    strongSelf.collectionView.reloadEmptyDataSet()
                }
                strongSelf.ref.child("user-posts/\(user.uid)").observe(.value, with: { [weak self] (snapshot) in
                    guard let strongSelf = self else { return }
                    for child in snapshot.children {
                        if
                            let snapshot = child as? DataSnapshot,
                            let post = Post(snapshot: snapshot)
                        {
                            if
                                let existingPostIndex = strongSelf.posts.index(where: { $0.key == post.key }) {
                                strongSelf.posts.remove(at: existingPostIndex)
                                strongSelf.posts.insert(post, at: existingPostIndex)
                            } else {
                                strongSelf.posts.append(post)
                            }
                        }
                    }
                    strongSelf.collectionView.reloadData()
                })
            } else {

            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    deinit {
        self.handler = nil
    }

}

extension UserAccountViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "post", for: cellForItemAt) as! PostCollectionViewCell
        let url = URL(string: self.posts[cellForItemAt.row].photo)
        cell.imageView.kf.setImage(with: url)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
}

extension UserAccountViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width/3.0
        return CGSize(width: width, height: width)
    }
}

extension UserAccountViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attributes = [
            NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body),
            NSAttributedStringKey.foregroundColor: UIColor.darkGray
            ] as [NSAttributedStringKey: Any]
        return NSAttributedString(string: self.emptyMessage, attributes: attributes)
    }

}
