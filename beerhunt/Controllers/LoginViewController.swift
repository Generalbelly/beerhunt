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
import SVProgressHUD

class LoginViewController: AuthViewController {

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
    var userAuthenticated = false {
        didSet {
            self.delegate?.authView(didAuthenticate: self.userAuthenticated)
            if self.userAuthenticated {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.validator.registerField(self.emailField, errorLabel: self.emailErrorLabel, rules: [RequiredRule(message: "必須項目です"), EmailRule(message: "不正なメールアドレスです")])
        self.validator.registerField(self.passwordField, errorLabel: self.passwordErrorLabel, rules: [RequiredRule(message: "必須項目です")])

        self.navigationController?.navigationBar.barTintColor = .black
        self.navigationController?.navigationBar.tintColor = .lightText
        self.navigationController?.navigationBar.isTranslucent = false

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        self.validator.unregisterField(self.emailField)
        self.validator.unregisterField(self.passwordField)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let svc = segue.destination as? SignupViewController {
            svc.delegate = self
        }
    }
}

extension LoginViewController: ValidationDelegate {

    func validationSuccessful() {
        guard
            let email = self.emailField.text,
            let password = self.passwordField.text
        else { return }

        SVProgressHUD.show()
        Auth.auth().signIn(withEmail: email, password: password) { (authDataResult, error) in
            SVProgressHUD.dismiss()
            if
                let error = error,
                let errorCode = AuthErrorCode(rawValue: (error as NSError).code)
            {
                self.loginErrorLabel.textColor = .red
//                self.loginErrorLabel.text = error.localizedDescription
                self.loginErrorLabel.text = errorCode.errorMessage
                self.userAuthenticated = false
            } else if authDataResult != nil {
                self.userAuthenticated = true
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

extension LoginViewController: AuthViewControllerDelegate {
    func authView(didAuthenticate: Bool) {
        self.userAuthenticated = didAuthenticate
    }
}
