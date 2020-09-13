//
//  CropViewController.swift
//  VideoConverter_Example
//
//  Created by Apple on 2020/09/13.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import CropPickerView

protocol CropDelegate: class {
    func cropImage(_ imageSize: CGSize, cropFrame: CGRect)
}

class CropViewController: UIViewController {
    weak var delegate: CropDelegate?

    private var cropView: CropPickerView = {
        let view = CropPickerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cropLineColor = .white
        view.dimBackgroundColor = UIColor(white: 0, alpha: 0.6)
        return view
    }()

    private let image: UIImage

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.clipsToBounds = true
        self.view.backgroundColor = .black
        self.view.addSubview(self.cropView)

        var bottomConstant: CGFloat = 0
        if #available(iOS 11.0, *) {
            bottomConstant = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        self.view.addConstraints([
            NSLayoutConstraint(item: self.cropView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 10),
            NSLayoutConstraint(item: self.cropView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -(bottomConstant + 10)),
            NSLayoutConstraint(item: self.cropView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 10),
            NSLayoutConstraint(item: self.cropView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -10)
        ])

        DispatchQueue.main.async {
            self.cropView.image(self.image, isMin: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(self.closeTab(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Crop", style: .plain, target: self, action: #selector(self.cropTab(_:)))

        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = .black
        self.navigationController?.navigationBar.backgroundColor = .black
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }

    @objc private func closeTab(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func cropTab(_ sender: UIButton) {
        self.cropView.crop { [weak self] (crop) in
            guard let self = self else { return }
            if let error = crop.error {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            if let cropFrame = crop.cropFrame, let imageSize = crop.imageSize {
                self.dismiss(animated: true) {
                    self.delegate?.cropImage(imageSize, cropFrame: cropFrame)
                }
            }
        }
    }
}
