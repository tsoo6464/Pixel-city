//
//  Constants.swift
//  Pixel-city
//
//  Created by Nan on 2018/2/8.
//  Copyright © 2018年 nan. All rights reserved.
//

import Foundation

let API_KEY = "cce56c015a368ee03b06820cd06fe3d8"
// getFlickrURL
func flickrURL(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhoto number: Int) -> String {
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    return url
}

typealias CompletionHandler = (_ success: Bool) -> ()
// Identifier
let DROPPABLE_PIN = "droppablePin"
let PHOTO_CELL = "photoCell"
