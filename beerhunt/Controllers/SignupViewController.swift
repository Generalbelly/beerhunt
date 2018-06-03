//
//  SignupViewController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/06/02.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import SwiftValidator
import Firebase

class SignupViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    @IBOutlet weak var passwordConfirmationField: UITextField!
    @IBOutlet weak var passwordConfirmationErrorLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var usernameErrorLabel: UILabel!

    @IBOutlet weak var signupButtton: UIButton!
    @IBAction func signupButttonTapped(_ sender: Any) {
        self.emailErrorLabel.textColor = .clear
        self.passwordErrorLabel.textColor = .clear
        self.passwordConfirmationErrorLabel.textColor = .clear
        self.usernameErrorLabel.textColor = .clear
        self.signupErrorLabel.textColor = .clear
        self.validator.validate(self)
    }
    @IBOutlet weak var signupErrorLabel: UILabel!

    let validator = Validator()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.validator.registerField(self.emailField, errorLabel: self.emailErrorLabel, rules: [RequiredRule(message: "必須項目です"), EmailRule(message: "不正なメールアドレスです")])
        self.validator.registerField(self.passwordField, errorLabel: self.passwordErrorLabel, rules: [RequiredRule(message: "必須項目です"), MinLengthRule(length: 8, message: "パスワードは最低8文字以上にしてください")])
        self.validator.registerField(self.passwordConfirmationField, errorLabel: self.passwordConfirmationErrorLabel, rules: [RequiredRule(message: "必須項目です"), ConfirmationRule(confirmField: self.passwordField, message: "パスワードと一致しません")])
        self.validator.registerField(self.usernameField, errorLabel: self.usernameErrorLabel, rules: [RequiredRule(message: "必須項目です")])

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
        self.validator.unregisterField(self.passwordConfirmationField)
        self.validator.unregisterField(self.usernameField)
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

extension SignupViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.dismissKeyboard()
        return true
    }

}

extension SignupViewController: ValidationDelegate {

    func validationSuccessful() {
        guard
            let email = self.emailField.text,
            let password = self.passwordField.text,
            let username = self.usernameField.text
        else { return }
        Auth.auth().createUser(withEmail: email, password: password, completion: { (authDataResult, error) in
            if let error = error {
                self.signupErrorLabel.textColor = .red
                self.signupErrorLabel.text = error.localizedDescription
            } else if authDataResult != nil {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = username
                changeRequest?.commitChanges(completion: { error in
                    if let error = error {
                        print(error.localizedDescription)
                        // TODO: send the error to server.
                    }
                })
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
