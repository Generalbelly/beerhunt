//
//  File.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/12.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import GooglePlaces

class PlacesClient {
    private let client = GMSPlacesClient.shared()

    func fetchGooglePlaceInfo(placeId: String, completion: @escaping (_ place: GMSPlace?) -> Void) {
        self.client.lookUpPlaceID(placeId, callback: {(place, error) -> Void in
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return completion(nil)
            }
            return completion(place)
        })
    }

    func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata, completion: @escaping (_ image: UIImage?) -> Void) {
        self.client.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
                return completion(nil)
            } else {
                return completion(photo)
            }
        })
    }

    func lookUpPhotos(placeId: String, completion: @escaping (GMSPlacePhotoMetadataList?) -> Void) {
        self.client.lookUpPhotos(forPlaceID: placeId) { (photos, error) in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
                completion(nil)
            }
            if let photos = photos {
                completion(photos)
            } else {
                completion(nil)
            }
        }
    }

}
