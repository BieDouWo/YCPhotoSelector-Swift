//
//  YCPhotoSelectorModel.swift
//  SwiftDemo
//
//  Created by zz on 2017/2/10.
//  Copyright © 2017年 Shenzhen Turen Technology Inc. All rights reserved.
//

import UIKit
import Photos

class YCPhotoSelectorModel {
    
    var fetchResult: PHFetchResult<PHAsset>?  //当前目录
    var asset: PHAsset?                       //相册封面图
    var albumName: String?                    //相册名称
    var albumNum: Int?                        //当前相册资源数量
    var assetArr: Array<Any>?                 //当前相册资源
}
