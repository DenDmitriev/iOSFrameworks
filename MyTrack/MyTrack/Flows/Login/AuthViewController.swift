//
//  AuthViewController.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 07.02.2023.
//

import UIKit

class AuthViewController: UIViewController {
    
    enum Constant {
        static let login = "user"
        static let password = "1234"
    }
    
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passTextFiled: UITextField!
    
    var onLogin: (() -> Void)?
    var onRecover: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func registDidTaped(_ sender: UIButton) {
        print(#function)
    }
    
    @IBAction func loginDidTaped(_ sender: UIButton) {
        guard
            let login = loginTextField.text,
            let pass = passTextFiled.text,
            login == Constant.login && pass == Constant.password
        else {
            return
        }
        print("login")
        
        UserDefaults.standard.set(true, forKey: "isLogin")
        
        onLogin?()
    }
    
    @IBAction func restoreDidTaped(_ sender: Any) {
        onRecover?()
    }

}
