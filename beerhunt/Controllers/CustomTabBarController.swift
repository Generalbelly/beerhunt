//
//  CustomTabBarController.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/20.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import UIKit
import YPImagePicker
import Firebase

class CustomTabBarController: UITabBarController {

    var currentTabIndex = 0 {
        didSet {
            self.previousTabIndex = oldValue
        }
    }
    var previousTabIndex = 0 {
        didSet {
            if self.previousTabIndex != 2 {
                self.beforeImagePickerIndex = self.previousTabIndex
            }
        }
    }
    var beforeImagePickerIndex = 0

    var picker: YPImagePicker? {
        didSet {
            guard let picker = self.picker else { return }
            picker.didCancel = {
                self.selectedIndex = self.beforeImagePickerIndex
            }
            picker.didSelectImage = { image in
                guard
                    let picker = self.picker,
                    let prvc = self.storyboard?.instantiateViewController(withIdentifier: "postRestaurantViewController") as? PostRestaurantViewController
                else { assert(false) }
                prvc.image = image
                picker.pushViewController(prvc, animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UINavigationBar.appearance().barTintColor = UIColor.init(red: 246/255.0, green: 166/255.0, blue: 35/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = .darkText
        UINavigationBar.appearance().isTranslucent = false
        UITabBar.appearance().tintColor = UIColor.init(red: 246/255.0, green: 166/255.0, blue: 35/255.0, alpha: 1.0)

        self.delegate = self

        // Photo uploading related screens
        var config = YPImagePickerConfiguration()
        config.libraryTargetImageSize = .original
        config.usesFrontCamera = true
        config.shouldSaveNewPicturesToAlbum = true
        config.screens = [.library, .photo]
        config.startOnScreen = .library
        config.showsCrop = .rectangle(ratio: (1/1))
        config.hidesStatusBar = false
        config.wordings.next = "次へ"

        // Build a picker with your configuration
        self.picker = YPImagePicker(configuration: config)
    }

    deinit {
        self.picker = nil
    }
}

extension CustomTabBarController: UITabBarControllerDelegate {

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard
            let items = tabBar.items,
            let index = items.index(of: item)
            else
        { return }

        self.currentTabIndex = index
        if index == 2 {
            if Auth.auth().currentUser != nil {
//                do {
//                    try Auth.auth().signOut()
//                } catch {
//
//                }
                self.showPicker()
            } else {
                self.performSegue(withIdentifier: "login", sender: nil)
            }
        } else {
            self.selectedIndex = self.currentTabIndex
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return false
    }

    func showPicker() {
        guard let picker = self.picker else { return }
        self.present(picker, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            let nvc = segue.destination as? UINavigationController,
            let lvc = nvc.topViewController as? LoginViewController
        {
            lvc.delegate = self
        }
    }
}

extension CustomTabBarController: AuthViewControllerDelegate {
    func authView(didAuthenticate: Bool) {
        if didAuthenticate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showPicker()
            }
        }
    }
}
