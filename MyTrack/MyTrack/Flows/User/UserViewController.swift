//
//  UserViewController.swift
//  MyTrack
//
//  Created by Denis Dmitriev on 07.02.2023.
//

import UIKit

class UserViewController: UIViewController {
    
    var onLogout: (() -> Void)?
    var toTrack: ((String) -> Void)?
    
    var viewModel: UserViewModel?
    weak var coordinator: UserCoordinator?
    
    @IBOutlet weak var userView: UserView!
    @IBOutlet weak var loginLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure() {
        viewModel = UserViewModel()
        if let user = viewModel?.getUser() {
            loginLabel.text = user.login
            userView.image = viewModel?.getUserImage()
        }
    }
    
    @IBAction func toTrackDidTaped(_ sender: UIButton) {
        toTrack?("👾 Some Value")
    }
    
    @IBAction func logoutDidTaped(_ sender: UIButton) {
        UserDefaults.standard.set(false, forKey: "isLogin")
        onLogout?()
    }
    
    @IBAction func imagePickerAction(_ sender: UIButton) {
        coordinator?.toPicker()
    }

}

extension UserViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print(#function)
        guard
            let image = info[.editedImage] as? UIImage
        else { return }
        
        viewModel?.saveImage(image: image)
        
        if let image = viewModel?.getUserImage() {
            userView.image = image
        }
        
        dismiss(animated: true)
    }
}
