//
//  RequestFormViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/18.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import Eureka
import FirebaseDatabase

class RequestFormViewController: FormViewController {
    
    var alertController: UIAlertController! {
        didSet {
            let OKAction = UIAlertAction(title: "Done", style: .default) { [unowned self] _ in
                self.dismiss(animated: true, completion: nil)
                if let row = self.form.rowBy(tag: "message") as? TextAreaRow {
                    row.value = ""
                }
                if let row = self.form.rowBy(tag: "email") as? EmailRow {
                    row.value = ""
                }
                if let row = self.form.rowBy(tag: "feature") as? AlertRow<String> {
                    row.value = ""
                    row.updateCell()
                }
            }
            self.alertController.addAction(OKAction)
        }
    }
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        form +++ Section(header: "ご意見・ご要望等ありましたらお気軽にお寄せください。", footer: "")
            <<< AlertRow<String>() {
                $0.title = "追加して欲しい機能"
                $0.selectorTitle = "一番欲しい機能を教えてください"
                $0.options = ["飲んだビールの記録が取れる機能", "お店の情報・写真の投稿機能", "SNS機能"]
                $0.value = "未選択"
                $0.tag = "feature"
            }
            .onPresent{ _, to in
                to.cancelTitle = "キャンセル"
            }
            <<< TextAreaRow() {
                $0.placeholder = "ご意見・ご要望"
                $0.tag = "message"
            }
            <<< EmailRow() {
                $0.title = "Email（任意）"
                $0.placeholder = "youremail@example.com"
                $0.tag = "email"
            }
            <<< ButtonRow() {
                $0.title = "送信"
            }
            .onCellSelection { [unowned self] cell, row in
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
                self.present(self.alertController, animated: true)
            }
        self.alertController = UIAlertController(title: "ありがとうございます！", message: "アプリ改善に役立たせていただきます。", preferredStyle: .alert)
    }
    
}
