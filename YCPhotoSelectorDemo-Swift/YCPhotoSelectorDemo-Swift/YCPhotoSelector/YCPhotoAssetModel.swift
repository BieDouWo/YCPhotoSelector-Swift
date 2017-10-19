//
//  YCPhotoAssetModel.swift
//  SwiftDemo
//
//  Created by zz on 2017/2/15.
//  Copyright © 2017年 Shenzhen Turen Technology Inc. All rights reserved.
//

import UIKit
import Photos

class YCPhotoAssetModel {
    
    var asset: PHAsset?
    var isChecked: Bool?
    
    init(asset: PHAsset) {
        self.asset = asset
        self.isChecked = false
    }
}
