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
import SVProgressHUD

class SignupViewController: AuthViewController {

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
    var userAuthenticated = false {
        didSet {
            self.delegate?.authView(didAuthenticate: self.userAuthenticated)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.validator.registerField(self.emailField, errorLabel: self.emailErrorLabel, rules: [RequiredRule(message: "必須項目です"), EmailRule(message: "不正なメールアドレスです")])
        self.validator.registerField(self.passwordField, errorLabel: self.passwordErrorLabel, rules: [RequiredRule(message: "必須項目です"), MinLengthRule(length: 6, message: "パスワードは最低6文字以上にしてください")])
        self.validator.registerField(self.passwordConfirmationField, errorLabel: self.passwordConfirmationErrorLabel, rules: [RequiredRule(message: "必須項目です"), ConfirmationRule(confirmField: self.passwordField, message: "パスワードと一致しません")])
        self.validator.registerField(self.usernameField, errorLabel: self.usernameErrorLabel, rules: [RequiredRule(message: "必須項目です")])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        self.validator.unregisterField(self.emailField)
        self.validator.unregisterField(self.passwordField)
        self.validator.unregisterField(self.passwordConfirmationField)
        self.validator.unregisterField(self.usernameField)
    }
}

extension SignupViewController: ValidationDelegate {

    func validationSuccessful() {
        guard
            let email = self.emailField.text,
            let password = self.passwordField.text,
            let username = self.usernameField.text
        else { return }

        SVProgressHUD.show()
        Auth.auth().createUser(withEmail: email, password: password, completion: { (authDataResult, error) in
            SVProgressHUD.dismiss()
            if
                let error = error,
                let errorCode = AuthErrorCode(rawValue: (error as NSError).code)
            {
                self.signupErrorLabel.textColor = .red
                self.signupErrorLabel.text = errorCode.errorMessage
                self.userAuthenticated = false
            } else if authDataResult != nil {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = username
                changeRequest?.commitChanges(completion: { error in
                    if let error = error {
                        print(error.localizedDescription)
                        // TODO: send the error to server.
                    }
                })
                if let user = Auth.auth().currentUser {
                    user.sendEmailVerification(completion: nil)
                }
                self.userAuthenticated = true
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
