//
//  YCPhotoAssetCell.swift
//  SwiftDemo
//
//  Created by zz on 2017/2/16.
//  Copyright © 2017年 Shenzhen Turen Technology Inc. All rights reserved.
//

import UIKit
import Photos

class YCPhotoAssetCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView! //缩略图
    @IBOutlet weak var checkedView: UIView!             //勾选模糊视图
    @IBOutlet weak var highlightedView: UIView!         //高亮背景
    @IBOutlet weak var videoBaseView: UIView!           //视频底视图
    @IBOutlet weak var blackBaseView: UIView!           //视频半透明黑色背景
    @IBOutlet weak var videoTimeLabel: UILabel!         //视频时间
    
    weak var photoAssetVC: YCPhotoAssetVC?
    
    //MARK: - 加载视图
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //设置勾选背景颜色为偏白模糊
        checkedView.backgroundColor = UIColor.init(white: 1, alpha: 0.4)
    }
    
    //MARK: - 高亮时
    override var isHighlighted: Bool {
        didSet {
            highlightedView.alpha = isHighlighted ? 0.5 : 0.0
        }
    }
   
    //MARK: - 刷新数据
    func refreshPhotoAsset(model: YCPhotoAssetModel) {
        
        //设置视频半透明黑色背景
        var rect: CGRect = blackBaseView.frame
        rect.size.width = self.frame.size.width
        blackBaseView.frame = rect
        
        //必须要判断这个是否是nil
        if blackBaseView.layer.sublayers != nil {
            for layer in blackBaseView.layer.sublayers! {
                if layer.isKind(of: CAGradientLayer.classForCoder()) {
                    layer.removeFromSuperlayer()
                }
            }
        }
        self.insertTransparentGradient(view: blackBaseView)
        
        //设置封面图
        PHImageManager.default().requestImage(for: model.asset!, targetSize: photoAssetVC!.thumbnailSize, contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: {(result, info) in
            
            self.thumbnailImageView.image = result
        })
        
        //判断资源类型
        if model.asset?.mediaType == PHAssetMediaType.video {
            let duration: Int = Int((model.asset?.duration)!)
            let min: Int = duration / 60
            let sec: Int = duration % 60
            
            videoBaseView.isHidden = false
            videoTimeLabel.text = String(format: "%02d:%02d", min, sec)
        }else{
            videoBaseView.isHidden = true
        }
        
        //判断是否勾选
        if model.isChecked! {
            checkedView.isHidden = false
        }else{
            checkedView.isHidden = true
        }
    }
    
    //MARK: - 设置view渐变黑色背景
    func insertTransparentGradient(view: UIView) {
        
        let colorOne: UIColor = UIColor.init(red: (33/255.0), green: (33/255.0), blue: (33/255.0), alpha: 0.0)
        let colorTwo: UIColor = UIColor.init(red: (33/255.0), green: (33/255.0), blue: (33/255.0), alpha: 0.5)
        let colors: Array = [colorOne.cgColor, colorTwo.cgColor]
        
        let stopOne: NSNumber = NSNumber(value: 0.0)
        let stopTwo: NSNumber = NSNumber(value: 0.5)
        let locations: Array = [stopOne, stopTwo]
        
        let headerLayer: CAGradientLayer = CAGradientLayer()
        headerLayer.colors = colors
        headerLayer.locations = locations
        headerLayer.frame = view.bounds
        headerLayer.startPoint = CGPoint(x: 0.0, y:0.0)
        headerLayer.endPoint = CGPoint(x: 0.0, y:2.0)
        view.layer.insertSublayer(headerLayer, at: 0)
    }
}



