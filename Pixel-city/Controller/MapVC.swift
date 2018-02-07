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
    // 視窗大小
    let screenSize = UIScreen.main.bounds
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
    }
    // 設定雙擊地圖放置地圖大頭針手勢
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MapVC.dropPin(sender:)))
        // 設定tap幾下
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    //
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
        guard let spin = spinner else { return }
        spin.activityIndicatorViewStyle = .whiteLarge
        spin.center = CGPoint(x: (screenSize.width / 2) - (spin.frame.size.width / 2), y: 150 - (spin.frame.size.height))
        spin.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spin.startAnimating()
        pullUpView.addSubview(spin)
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
        
        let pinAnnotitaion = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
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
        animateViewUp()
        addSwipe()
        addSpinner()
        // 取得使用者點擊的螢幕座標
        let touchPoint = sender.location(in: mapView)
        // 轉換成GPS座標
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        // 建立大頭針
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
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