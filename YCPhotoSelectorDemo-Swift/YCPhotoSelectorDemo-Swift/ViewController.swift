//
//  ViewController.swift
//  YCPhotoSelectorDemo-Swift
//
//  Created by 别逗我 on 2017/10/19.
//  Copyright © 2017年 YuChengGuo. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, YCPhotoSelectorVCDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
    }

    @IBAction func goPhotoSelector(_ sender: Any)
    {
        let photoVC : YCPhotoSelectorVC = YCPhotoSelectorVC.photoSelectorVC()
        
        //设置选择的类型 - 不限制类型
        photoVC.mediaType = PHAssetMediaType.unknown
        
        //设置限制选择的个数
        photoVC.maxNum = 3
        
        //弹出并设置代理
        photoVC.show(controller: self, delegate: self)
    }
    
    //YCPhotoSelectorVCDelegate
    func finish(photoSelectorVC: YCPhotoSelectorVC, assetArr: Array<Any>)
    {
        //取出选择的最后一个
        let asset : PHAsset = assetArr.last as! PHAsset
        
        //图片大小
        let scale : CGFloat = UIScreen.main.scale
        let imageSize : CGSize = CGSize(width: 100, height: 100)
        let size : CGSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        //获取图片
        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: {(result, info) in
            
            self.imageView.image = result
        })
    }
}


