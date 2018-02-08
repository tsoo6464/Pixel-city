//
//  PopVC.swift
//  Pixel-city
//
//  Created by Nan on 2018/2/8.
//  Copyright © 2018年 nan. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {
    // Outlets
    @IBOutlet weak var popImageView: UIImageView!
    // Varialbe
    var passedImage: UIImage!
    
    func initData(forImage image: UIImage) {
        self.passedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = passedImage
        addDoubleTap()
    }
    // 添加雙擊螢幕回上一頁手勢
    func addDoubleTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(PopVC.screenWasDoubleTapped))
        tap.numberOfTapsRequired = 2
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    @objc func screenWasDoubleTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
