//
//  YCPhotoSelectorCell.swift
//  SwiftDemo
//
//  Created by zz on 2017/2/10.
//  Copyright © 2017年 Shenzhen Turen Technology Inc. All rights reserved.
//

import UIKit
import Photos

class YCPhotoSelectorCell: UITableViewCell {

    @IBOutlet weak var lineView: UIView!             //分割线
    @IBOutlet weak var albumImageView: UIImageView!  //相册封面图
    @IBOutlet weak var albumNameLabel: UILabel!      //相册名称
    @IBOutlet weak var albumNumLabel: UILabel!       //当前相册图片视频数量
    
    //缩略图大小
    var thumbnailSize: CGSize = CGSize.zero
    
    //MARK: - 加载视图
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //设置分割线
        self.addSubview(lineView)
        
        //设置缩略图大小
        let scale: CGFloat = CGFloat(UIScreen.main.scale)
        
        let imageViewSize: CGSize = CGSize(width: albumImageView.frame.size.width, height: albumImageView.frame.size.height)
        
        thumbnailSize = CGSize(width: (imageViewSize.width * scale), height: (imageViewSize.height * scale))
    }

    //MARK: - 刷新数据
    func refreshPhotoSelector(model: YCPhotoSelectorModel) {
        //相册名称
        albumNameLabel.text = model.albumName
        
        //当前相册图片视频数量
        albumNumLabel.text = String(format: "%d", model.albumNum!)

        //设置封面图
        PHImageManager.default().requestImage(for: model.asset!, targetSize: thumbnailSize, contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: {(result, info) in
            
            self.albumImageView.image = result
        })
    }
}



