//
//  RequestFormViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/18.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import Eureka
import Firebase

class RequestFormViewController: FormViewController {

    var alertController: UIAlertController?
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        form +++ Section(header: "ご意見・ご要望等ありましたらお気軽にお寄せください。", footer: "")
            <<< AlertRow<String> { row in
                row.title = "追加して欲しい機能"
                row.selectorTitle = "一番欲しい機能を教えてください"
                row.options = [
                    "お店の情報・写真の投稿機能",
                    "飲んだビールの記録が取れる機能",
                    "SNS機能",
                    "その他"
                ]
                row.tag = "feature"
            }
            .onPresent { _, toScreen in
                toScreen.optionsProviderRow.cancelTitle = "キャンセル"
            }
            <<< TextAreaRow { row in
                row.placeholder = "ご意見・ご要望"
                row.tag = "message"
            }
            <<< EmailRow { row in
                row.title = "Email（任意）"
                row.placeholder = "youremail@example.com"
                row.tag = "email"
            }
            <<< ButtonRow { row in
                row.title = "送信"
            }
            .onCellSelection { [unowned self] _, row in
                var data: [String: String] = [:]
                if let row = self.form.rowBy(tag: "message") as? TextAreaRow {
                    data["message"] = row.value
                }
                if let row = self.form.rowBy(tag: "email") as? EmailRow {
                    data["email"] = row.value
                }
                if let row = self.form.rowBy(tag: "feature") as? AlertRow<String> {
                    data["feature"] = row.value
                }
                let uid = self.ref.childByAutoId().key
                self.ref.child("feedback").child(uid).setValue(data)
                self.presentThanksMessage()
            }
    }

    func presentThanksMessage() {
        if self.alertController == nil {
            self.alertController = UIAlertController(title: "ありがとうございます！", message: "アプリ改善に役立たせていただきます。", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "閉じる", style: .default) { [unowned self] _ in
                self.alertController!.dismiss(animated: true, completion: { [unowned self] in
                    self.alertController = nil
                })
                if let row = self.form.rowBy(tag: "message") as? TextAreaRow {
                    row.value = ""
                    row.updateCell()
                }
                if let row = self.form.rowBy(tag: "email") as? EmailRow {
                    row.value = ""
                    row.updateCell()
                }
                if let row = self.form.rowBy(tag: "feature") as? AlertRow<String> {
                    row.value = ""
                    row.updateCell()
                }
            }
            self.alertController?.addAction(OKAction)
        }
        self.present(self.alertController!, animated: true)
    }

}
