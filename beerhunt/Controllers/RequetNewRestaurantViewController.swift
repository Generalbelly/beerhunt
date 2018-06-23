//
//  RequetNewRestaurantViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/06/16.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Eureka
import Firebase

class RequetNewRestaurantViewController: FormViewController {

    var alertController: UIAlertController?
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        form +++ Section(header: "レストランの新規追加", footer: "")
            <<< TextRow { row in
                row.title = "店名"
                row.placeholder = "エンジェルクラフト"
                row.tag = "name"
            }
            <<< TextRow { row in
                row.title = "住所"
                row.placeholder = "東京都中央区日本橋室町99-1"
                row.tag = "address"
            }
            <<< TextAreaRow { row in
                row.placeholder = "その他なにかあれば自由にお書きください"
                row.tag = "message"
            }
            <<< EmailRow { row in
                row.title = "あなたのEmail（任意）"
                row.placeholder = "youremail@example.com"
                row.tag = "email"
                row.validationOptions = .validatesOnChangeAfterBlurred
            }
            <<< ButtonRow { row in
                row.title = "送信"
                }
                .onCellSelection { [unowned self] _, row in
                    var data: [String: String] = [:]
                    guard
                        let nameRow = self.form.rowBy(tag: "name") as? TextRow,
                        let name = nameRow.value,
                        let addressRow = self.form.rowBy(tag: "address") as? TextRow,
                        let address = addressRow.value
                    else {
                        self.showAlertVC(title: "必須項目が入力されていません", message: "店名と住所は必須です")
                        return
                    }
                    data["name"] = name
                    data["address"] = address

                    if let row = self.form.rowBy(tag: "message") as? TextAreaRow {
                        data["message"] = row.value
                    }
                    if let row = self.form.rowBy(tag: "email") as? EmailRow {
                        data["email"] = row.value
                    }
                    let uid = self.ref.childByAutoId().key
                    self.ref.child("new_restaurants").child(uid).setValue(data)
                    self.form.validate()
                    if let row = self.form.rowBy(tag: "message") as? TextAreaRow {
                        row.value = ""
                        row.updateCell()
                    }
                    if let row = self.form.rowBy(tag: "email") as? EmailRow {
                        row.value = ""
                        row.updateCell()
                    }
                    if let row = self.form.rowBy(tag: "name") as? TextRow {
                        row.value = ""
                        row.updateCell()
                    }
                    if let row = self.form.rowBy(tag: "address") as? TextRow {
                        row.value = ""
                        row.updateCell()
                    }
                    self.showAlertVC(title: "ありがとうございます！", message: "送信された情報は内容を確認次第、beerhuntに反映されます")
        }
    }

    func showAlertVC(title: String, message: String) {
        if self.alertController == nil {
            self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let completeAction = UIAlertAction(title: "閉じる", style: .default) { [unowned self] _ in
                self.alertController!.dismiss(animated: true, completion: { [unowned self] in
                    self.alertController = nil
                })
            }
            self.alertController!.addAction(completeAction)
        } else {
            self.alertController?.title = title
            self.alertController?.message = message
        }
        self.present(self.alertController!, animated: true)
    }

}
