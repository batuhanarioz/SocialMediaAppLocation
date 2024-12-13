//
//  CloudinaryManager.swift
//  KonumUyg
//
//  Created by reel on 13.11.2024.
//


import Cloudinary

class CloudinaryManager {
    static let shared: CLDCloudinary = {
        let config = CLDConfiguration(cloudName: "dbnojset9", apiKey: "274538773668395", apiSecret: "6UFCVmBV_DoUFD7cjdVS4CVpAR4")
        let cloudinary = CLDCloudinary(configuration: config)
        return cloudinary
    }()
}
