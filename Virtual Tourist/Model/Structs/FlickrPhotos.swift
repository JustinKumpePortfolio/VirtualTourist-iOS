//
//  FlickrPhotos.swift
//  Virtual Tourist
//
//  Created by Justin Kumpe on 8/23/20.
//  Copyright © 2020 Justin Kumpe. All rights reserved.
//

import Foundation

struct FlickrPhotos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [FlickrPhoto]
}
