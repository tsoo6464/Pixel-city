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
import Alamofire
import AlamofireImage

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
    // collectionView
    var collectionView: UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    // 放在collectionView上的UI
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    // 存放圖片下載的URL的Array
    var imageURLArray = [String]()
    // 存放圖片的Array
    var imageArray = [UIImage]()
    var imageIdArray = [String]()
    
    
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
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        pullUpView.addSubview(collectionView!)
        
        registerForPreviewing(with: self, sourceView: collectionView!)
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
        cancelAllSessions()
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
        progressLbl?.font = UIFont(name: "Avenir Next", size: 14)
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
        cancelAllSessions()
        imageArray = []
        imageURLArray = []
        imageIdArray = []
        collectionView?.reloadData()
        
        
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
        animateViewUp()
        // 設定座標範圍並將畫面以座標為中心點
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        // 下載大頭針指到的位置周圍的照片
        retrieveUrls(forAnnotation: annotation) { (success) in
            if success {
                self.retrieveImages(completion: { (success) in
                    if success {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    // 移除所有大頭針
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    // 獲得照片的URL
    func retrieveUrls(forAnnotation annotation: DroppablePin, completion: @escaping CompletionHandler) {
        Alamofire.request(flickrURL(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhoto: 40)).responseJSON { (response) in
            if response.result.error == nil {
                guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
                let photosDict = json["photos"] as! Dictionary<String, AnyObject>
                let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
                for photo in photosDictArray {
                    let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                    self.imageURLArray.append(postUrl)
                    self.imageIdArray.append(photo["id"] as! String)
                }
                completion(true)
            } else {
                completion(false)
                debugPrint(response.result.error as Any)
            }
        }
    }
    // 獲得圖片並加入到imageArray裡面
    func retrieveImages(completion: @escaping CompletionHandler) {
        for url in imageURLArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                if response.result.error == nil {
                    guard let image = response.result.value else { return }
                    self.imageArray.append(image)
                    // progressLbl秀出已經載入幾張圖片了
                    self.progressLbl?.text = "\(self.imageArray.count)/40 IMAGES DOWNLOADED"
                    if self.imageArray.count == self.imageURLArray.count {
                        completion(true)
                    }
                } else {
                    completion(false)
                    debugPrint(response.result.error as Any)
                }
            })
        }
    }
    func retrievePhotoInfo(forId Id: String, forImage image: UIImage,  completion: @escaping CompletionHandler) {
        Alamofire.request(flickrPhotoInfo(forPhotoId: Id)).responseJSON { (response) in
            if response.result.error == nil {
                PhotoService.instance.photo.removeAll()
                guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
                let photoDict = json["photo"] as! Dictionary<String, AnyObject>
                let photoOwner = photoDict["owner"] as! Dictionary<String, AnyObject>
                let photoOwnerName = photoOwner["username"] as! String
                let photoTitle = photoDict["title"] as! Dictionary<String, AnyObject>
                let photoTitleContent = photoTitle["_content"] as! String
                let photoDescription = photoDict["description"] as! Dictionary<String, AnyObject>
                let photoDescriptionContent = photoDescription["_content"] as! String
                let newPhoto = Photo(image: image, title: photoTitleContent, description: photoDescriptionContent, ownerName: photoOwnerName)
            PhotoService.instance.photo.append(newPhoto)
                completion(true)
            } else {
                completion(false)
                debugPrint(response.result.error as Any)
            }
        }
    }
    // 取消所有執行的任務
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
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
        return self.imageArray.count
    }
    // cell內容物
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PHOTO_CELL, for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageView = UIImageView(image: imageArray[indexPath.row])
        cell.addSubview(imageView)
        return cell
    }
    // 點擊到的圖片
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: STORYBOARD_ID_POP) as? PopVC else { return }
        retrievePhotoInfo(forId: self.imageIdArray[indexPath.row], forImage: self.imageArray[indexPath.row], completion: { (success) in
            if success {
                self.present(popVC, animated: true, completion: nil)
            }
        })
    }
}
// 3D Touch
extension MapVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: STORYBOARD_ID_POP) as? PopVC else { return nil }
        retrievePhotoInfo(forId: self.imageIdArray[indexPath.row], forImage: self.imageArray[indexPath.row], completion: { (success) in })
        previewingContext.sourceRect = cell.contentView.frame
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
