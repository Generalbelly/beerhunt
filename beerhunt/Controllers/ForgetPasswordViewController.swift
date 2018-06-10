//
//  ForgetPasswordViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/06/03.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import SwiftValidator
import Firebase
import SVProgressHUD

class ForgetPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBAction func passwordResetTapped(_ sender: Any) {
        self.emailErrorLabel.textColor = .clear
        self.validator.validate(self)
    }
    @IBOutlet weak var passwordResetErrorLabel: UILabel!

    let validator = Validator()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.validator.registerField(self.emailField, errorLabel: self.emailErrorLabel, rules: [RequiredRule(message: "必須項目です"), EmailRule(message: "不正なメールアドレスです")])
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        self.validator.unregisterField(self.emailField)
    }

    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }

}

extension ForgetPasswordViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.dismissKeyboard()
        return true
    }

}

extension ForgetPasswordViewController: ValidationDelegate {

    func validationSuccessful() {
        guard let email = self.emailField.text else { return }

        SVProgressHUD.show()
        Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
            SVProgressHUD.dismiss()
            if let error = error {
                self.emailErrorLabel.text = error.localizedDescription
            } else {
                self.passwordResetErrorLabel.textColor = .white
                self.passwordResetErrorLabel.text = "パスワードのリセット用リンクを送信しました"
            }
        })
    }

    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        for (_, error) in errors {
            error.errorLabel?.textColor = .red
            error.errorLabel?.text = error.errorMessage
        }
    }

}
