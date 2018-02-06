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

class MapVC: UIViewController {
    // Outlets
    @IBOutlet weak var mapView: MKMapView!
    // Variables
    // 位置管理員
    var locationManager = CLLocationManager()
    // 授權
    let authorizationStatus = CLLocationManager.authorizationStatus()
    // 用來設定Region
    let regionRadius = 1000.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
    }
    // 取得所在位置的畫面
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
}

extension MapVC: MKMapViewDelegate {
    // 取得用戶位置 畫面移動到以座標為中心的位置
    func centerMapOnUserLocation() {
        // 取得座標資訊
        guard let coordinate = locationManager.location?.coordinate else { return }
        // 設定從取得座標開始的範圍為縮放大小
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0) // 位置資訊 & 基於座標位置的距離
        mapView.setRegion(coordinateRegion, animated: true)
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
