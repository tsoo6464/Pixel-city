//
//  MapVC.swift
//  Pixel-city
//
//  Created by Nan on 2018/2/5.
//  Copyright © 2018年 nan. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    // Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    // Variables
    // 位置管理員
    var locationManager = CLLocationManager()
    // 授權
    let authorizationStatus = CLLocationManager.authorizationStatus()
    // 用來設定Region
    let regionRadius = 1000.0
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    
    var collectionView: UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    // 視窗大小
    let screenSize = UIScreen.main.bounds
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        // 添加collectionView
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PHOTO_CELL)
        collectionView?.backgroundColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        pullUpView.addSubview(collectionView!)
    }
    // 設定雙擊地圖放置地圖大頭針手勢
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MapVC.dropPin(sender:)))
        // 設定tap幾下
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    // 設定下滑手勢關閉pullView
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(MapVC.animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    // 彈出隱藏在最底下的view
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            // 更新view狀態
            self.view.layoutIfNeeded()
        }
    }
    // 將彈出的view收回底部並更新view狀態
    @objc func animateViewDown() {
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            // 更新view狀態
            self.view.layoutIfNeeded()
        }
    }
    // 添加載入圖片載入中的讀取標示
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.size.width)! / 2), y: 150)
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    // 移除載入讀取標示(不移除會一直重複增加)
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    // 在pullView上加入progressLbl
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 18)
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    // 移除progressLbl
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    // 取得所在位置的畫面
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    // 設定pin的樣式
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 若是用戶所在座標則不更換Pin設定
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotitaion = MKPinAnnotationView(annotation: annotation, reuseIdentifier: DROPPABLE_PIN)
        // 修改顏色跟放下動畫
        pinAnnotitaion.pinTintColor = #colorLiteral(red: 0.9647058824, green: 0.6509803922, blue: 0.137254902, alpha: 1)
        pinAnnotitaion.animatesDrop = true
        return pinAnnotitaion
    }
    
    // 取得用戶位置 畫面移動到以座標為中心的位置
    func centerMapOnUserLocation() {
        // 取得座標資訊
        guard let coordinate = locationManager.location?.coordinate else { return }
        // 設定從取得座標開始的範圍為縮放大小
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0) // 位置資訊 & 基於座標位置的距離
        mapView.setRegion(coordinateRegion, animated: true)
    }
    // 放置地圖大頭針
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLbl()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        // 取得使用者點擊的螢幕座標
        let touchPoint = sender.location(in: mapView)
        // 轉換成GPS座標
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        // 建立大頭針
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: DROPPABLE_PIN)
        // 地圖上加入大頭針
        mapView.addAnnotation(annotation)
        // 設定座標範圍並將畫面以座標為中心點
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    // 移除所有大頭針
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    // 檢查是否授權使用位置
    func configureLocationServices() {
        // 若並未授權 將請求用戶授權
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    // 獲得授權狀態時 設定畫面為位置中心
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    // 幾個集合
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    // 有幾個Item
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    // cell內容物
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PHOTO_CELL, for: indexPath) as! PhotoCell
        return cell
    }
}
