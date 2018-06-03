//
//  CustomAuthPickerViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/25.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import SwiftValidator
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    @IBAction func loginTapped(_ sender: Any) {
        self.emailErrorLabel.textColor = .clear
        self.passwordErrorLabel.textColor = .clear
        self.loginErrorLabel.textColor = .clear
        self.validator.validate(self)
    }
    @IBOutlet weak var loginErrorLabel: UILabel!

    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    let validator = Validator()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.validator.registerField(self.emailField, errorLabel: self.emailErrorLabel, rules: [RequiredRule(message: "必須項目です"), EmailRule(message: "不正なメールアドレスです")])
        self.validator.registerField(self.passwordField, errorLabel: self.passwordErrorLabel, rules: [RequiredRule(message: "必須項目です")])
        self.navigationController?.navigationBar.barTintColor = .black
        self.navigationController?.navigationBar.tintColor = .lightText
        self.navigationController?.navigationBar.isTranslucent = false

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.dismissKeyboard))
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
        self.validator.unregisterField(self.emailField)
        self.validator.unregisterField(self.passwordField)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
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

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.dismissKeyboard()
        return true
    }

}

extension LoginViewController: ValidationDelegate {

    func validationSuccessful() {
        guard
            let email = self.emailField.text,
            let password = self.passwordField.text
        else { return }

        Auth.auth().signIn(withEmail: email, password: password) { (authDataResult, error) in
            if error != nil {
                self.loginErrorLabel.textColor = .red
//                self.loginErrorLabel.text = error.localizedDescription
                self.loginErrorLabel.text = "認証情報に一致するユーザが見つかりませんでした"
            } else if authDataResult != nil {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        for (_, error) in errors {
            error.errorLabel?.textColor = .red
            error.errorLabel?.text = error.errorMessage
        }
    }

}
