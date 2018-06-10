//
//  AuthViewControllerProtocol.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/06/09.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import Firebase

protocol AuthViewControllerDelegate: class {
    func authView(didAuthenticate: Bool)
}

class AuthViewController: UIViewController {

    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size {
            if self.view.frame.origin.y == (UIApplication.shared.statusBarFrame.height + (self.navigationController?.navigationBar.frame.height)!) {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        let baseY = (UIApplication.shared.statusBarFrame.height + (self.navigationController?.navigationBar.frame.height)!)
        if self.view.frame.origin.y < baseY {
            self.view.frame.origin.y = baseY
        }
    }

    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }

}

extension AuthViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.dismissKeyboard()
        return true
    }

}

extension AuthErrorCode {
    var errorMessage: String {
        switch self {
        case .emailAlreadyInUse:
            return "メールアドレスが既に使用されています。"
        case .userNotFound:
            return "認証情報に一致するアカウントが見つかりません。"
        case .userDisabled:
            return "あなたのアカウントは現在停止しています。"
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            return "正しいメールアドレスを入力してください。"
        case .networkError:
            return "ネットワークエラーが発生しました。通信状況をご確認ください。"
        case .weakPassword:
            return "6 文字以上で、文字と数字を組み合わせた安全なパスワードを設定してください。"
        case .wrongPassword:
            return "パスワードが正しくはありません。パスワードを忘れた場合は、パスワードをリセットしてください。"
        default:
            return "不明なエラーが発生しました。"
        }
    }
}
