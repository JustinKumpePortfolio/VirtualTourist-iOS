//
//  FlickrPhotosResponse.swift
//  Virtual Tourist
//
//  Created by Justin Kumpe on 8/23/20.
//  Copyright © 2020 Justin Kumpe. All rights reserved.
//

import Foundation

struct FlickrPhotosResponse: Codable{
    let photos: FlickrPhotos
    let stat: String
}
