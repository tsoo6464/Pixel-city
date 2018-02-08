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
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var ownerNameLbl: UILabel!
    // Varialbe
    var passedImage: UIImage!
    var passedTitle: String!
    
    func initData(forImage image: UIImage) {
        self.passedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let photo = PhotoService.instance.photo[0]
        popImageView.image = photo.image
        titleLbl.text = photo.title
        descriptionLbl.text = photo.description
        ownerNameLbl.text = photo.ownerName
        if photo.title == "" {
            titleLbl.text = "照片沒有標題"
        }
        if photo.description == "" {
            descriptionLbl.text = "照片沒有描述"
        }
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
