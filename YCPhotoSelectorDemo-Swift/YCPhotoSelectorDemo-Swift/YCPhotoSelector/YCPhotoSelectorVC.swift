//
//  YCPhotoSelectorVC.swift
//  SwiftDemo
//
//  Created by zz on 2017/2/9.
//  Copyright © 2017年 Shenzhen Turen Technology Inc. All rights reserved.
//

import UIKit
import Photos

//@objc声明可选协议
@objc protocol YCPhotoSelectorVCDelegate {
    @objc optional func finish(photoSelectorVC: YCPhotoSelectorVC, assetArr: Array<Any>)
}

class YCPhotoSelectorVC: UIViewController, UITableViewDelegate, UITableViewDataSource, PHPhotoLibraryChangeObserver {

    @IBOutlet weak var photoSelectorTableView: UITableView! //列表视图
    @IBOutlet weak var permissionsBaseView: UIView!         //没有权限的提示视图
    @IBOutlet weak var noDataBaseView: UIView!              //没有数据的提示视图
    
    //筛选类型(默认只有照片)
    public var mediaType: PHAssetMediaType = PHAssetMediaType.image
    //最多选择的项(默认最多100张)
    var maxNum: Int = 100
    //代理对象
    weak var delegate: YCPhotoSelectorVCDelegate?
    
    var photoSelectorCellID: String = "YCPhotoSelectorCell"
    var photoSelectorArr: Array = Array<YCPhotoSelectorModel>()
    
    //MARK: - 释放资源
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    //MARK: - 加方法,不需要实例对象调用
    class func photoSelectorVC() -> YCPhotoSelectorVC {
        let photoSelectorVC: YCPhotoSelectorVC = YCPhotoSelectorVC(nibName: "YCPhotoSelectorVC" , bundle: nil)
        return photoSelectorVC
    }
    
    //MARK: - 弹出
    func show(controller: UIViewController, delegate: YCPhotoSelectorVCDelegate?) {
        self.delegate = delegate
        
        let naVC: UINavigationController = UINavigationController(rootViewController: self)
        controller.present(naVC, animated: true, completion: nil)
    }
    
    //MARK: - 加载视图
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "相薄"
        
        //设置取消按钮
        let rightItem: UIBarButtonItem = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancel))
        self.navigationItem.rightBarButtonItem = rightItem
        
        //设置头部和尾部分割线
        let w: Double = Double(UIScreen.main.bounds.size.width)
        let headLineView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: w, height: 0.5))
        headLineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
        photoSelectorTableView.tableHeaderView = headLineView
        photoSelectorTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //注册cell
        photoSelectorTableView.register(UINib(nibName: photoSelectorCellID, bundle: nil), forCellReuseIdentifier: photoSelectorCellID)
        
        //判断有权限访问系统相册(用户去开启或关闭都会重启app的)
        if self.isAlbumPermission() {
            permissionsBaseView.isHidden = true
        }
        
        //初始化相册资源
        self.photoLibraryDidChange(PHChange())
        
    #if false
        //列出所有相册智能相册(PHAssetCollectionTypeSmartAlbum:从iTunes同步来的相册,以及用户在Photos中自己建立的相册 PHAssetCollectionSubtypeSmartAlbumVideos:相机拍摄的视频)
        let smartAlbums : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.smartAlbumVideos, options: nil)
    #endif
        
        //监听系统相册变化
        PHPhotoLibrary.shared().register(self)
    }
    
    //MARK: - UITableView代理
    //多少组
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //多少行
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photoSelectorArr.count
    }
    
    //cell高
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    //返回cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: YCPhotoSelectorCell  = tableView.dequeueReusableCell(withIdentifier: photoSelectorCellID) as! YCPhotoSelectorCell
        
        cell.refreshPhotoSelector(model: photoSelectorArr[indexPath.row])
        
        return cell
    }
    
    //点击cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model: YCPhotoSelectorModel = photoSelectorArr[indexPath.row]
        let photoAssetVC: YCPhotoAssetVC = YCPhotoAssetVC(nibName: "YCPhotoAssetVC", bundle: nil)
        photoAssetVC.mediaType = mediaType
        photoAssetVC.maxNum = maxNum
        photoAssetVC.photoSelectorVC = self
        photoAssetVC.fetchResult = model.fetchResult
        photoAssetVC.directoryTitle = model.albumName
        photoAssetVC.assetArr = model.assetArr
        
        self.navigationController?.pushViewController(photoAssetVC, animated: true)
    }

    //MARK: - 监听系统相册变化
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        //必须主线程进行
        DispatchQueue.main.async {
            //先清空以前的
            self.photoSelectorArr.removeAll()

            //获取所有资源的集合,并按资源的创建时间排序
            let allPhotosOptions: PHFetchOptions = PHFetchOptions()
        
            //unknown:这个是未知的
            var allPhotos: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: allPhotosOptions)
            if self.mediaType != PHAssetMediaType.unknown {
                allPhotos = PHAsset.fetchAssets(with: self.mediaType, options: allPhotosOptions)
            }
            
            //判断资源大于0
            if allPhotos.count > 0 {
                let model: YCPhotoSelectorModel = YCPhotoSelectorModel()
                model.fetchResult = allPhotos
                model.albumName = "相机胶卷"
                model.albumNum = allPhotos.count
                
                //取出所以资源装到数组
                var assetArr : Array = Array<PHAsset>()
                for i in 0 ..< allPhotos.count {
                    let asset: PHAsset = allPhotos[i]
                    assetArr.append(asset)
                }
                model.assetArr = assetArr

                //设置封面图
                model.asset = assetArr.last
                
                //添加到数组
                self.photoSelectorArr.append(model)
            }
            
            //列出所有用户创建的相册
            let topLevelUserCollections : PHFetchResult = PHCollectionList.fetchTopLevelUserCollections(with: nil)
            
            //遍历所有用户创建的相册
            for i in 0 ..< topLevelUserCollections.count {
                //获取当前目录
                let assetCollection: PHAssetCollection = topLevelUserCollections[i] as! PHAssetCollection
                let fetchResult: PHFetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
                
                //判断当前目录资源大于0
                if fetchResult.count > 0 {
                    //找出符合筛选条件的资源
                    var assetArr: Array = Array<PHAsset>()
                    for j in 0 ..< fetchResult.count {
                        let asset: PHAsset = fetchResult[j]
                        //视频或图片
                        if asset.mediaType == self.mediaType && self.mediaType != PHAssetMediaType.unknown {
                            assetArr.append(asset)
                        }
                        //全部
                        if self.mediaType == PHAssetMediaType.unknown {
                            assetArr.append(asset)
                        }
                    }
                    //判断筛选后当前目录资源大于0
                    if assetArr.count > 0 {
                        let model: YCPhotoSelectorModel = YCPhotoSelectorModel()
                        model.fetchResult = fetchResult
                        model.albumName = assetCollection.localizedTitle
                        model.albumNum = assetArr.count
                        model.assetArr = assetArr
                        
                        //设置封面图
                        model.asset = assetArr.last
                        
                        //添加到数组
                        self.photoSelectorArr.append(model)
                    }
                }
            }
            
            //刷新数据
            self.photoSelectorTableView.reloadData()
            
            //判断没有一个数据
            self.noDataBaseView.isHidden = self.photoSelectorArr.count == 0 ? false : true
        }
    }
    
    //MARK: - 判断是否有权限访问相册
    func isAlbumPermission() -> Bool {
        let author: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        if author == PHAuthorizationStatus.restricted || author == PHAuthorizationStatus.denied {
            return false
        }
        return true
    }
    
    //MARK: - 取消选择
    @objc func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
}





