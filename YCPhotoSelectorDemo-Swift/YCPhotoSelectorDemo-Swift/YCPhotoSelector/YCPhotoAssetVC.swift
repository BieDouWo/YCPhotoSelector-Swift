//
//  YCPhotoAssetVC.swift
//  SwiftDemo
//
//  Created by zz on 2017/2/15.
//  Copyright © 2017年 Shenzhen Turen Technology Inc. All rights reserved.
//

import UIKit
import Photos

class YCPhotoAssetVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate {

    @IBOutlet weak var noDataBaseView: UIView!
    @IBOutlet weak var photoAssetCollectionView: UICollectionView!
    
    let VERTICAL_COLS: CGFloat = 4    //竖屏下照片多少列
    let HORIZONTAL_COLS: CGFloat = 6  //横屏下照片多少列
    
    var layout: UICollectionViewFlowLayout?
    var thumbnailSize: CGSize = CGSize.zero
    var photoAssetArr: Array<YCPhotoAssetModel>?
    
    weak var photoSelectorVC: YCPhotoSelectorVC?
    var mediaType: PHAssetMediaType?
    var maxNum: Int = 0
    
    var fetchResult: PHFetchResult<PHAsset>? //当前目录
    var directoryTitle: String?
    var assetArr: Array<Any>?
    
    var photoAssetCellID: String?
    var checkedCount: Int = 0
    var lastIndexPath: IndexPath?
    var panGestureRecognizer: UIPanGestureRecognizer?
    
    //MARK: - 释放资源
    deinit {
        NotificationCenter.default.removeObserver(self)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    //MARK: - 加载视图
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = directoryTitle
        photoAssetArr = Array<YCPhotoAssetModel>()
        
        //设置完成按钮
        let rightItem: UIBarButtonItem = UIBarButtonItem.init(title: "完成", style: UIBarButtonItemStyle.plain, target: self, action: #selector(finish))
        self.navigationItem.rightBarButtonItem = rightItem
        
        //设置顶部和底部悬空(必须放在这里)
        var currentInsets: UIEdgeInsets = photoAssetCollectionView.contentInset
        currentInsets.top = 0.5
        currentInsets.bottom = 0.0
        photoAssetCollectionView.contentInset = currentInsets
        
        //创建流水布局
        layout = UICollectionViewFlowLayout.init()
        
        //第一次加载判断设备方向
        self.deviceOrientationChange()
        
        //设置整个collectionView的内边距
        let paddingY: CGFloat = 1.0
        let paddingX: CGFloat = 1.0
        layout?.sectionInset = UIEdgeInsetsMake(paddingY, paddingX, paddingY, paddingX)
        
        //设置每一列之间的间距
        layout?.minimumInteritemSpacing = paddingX
        //设置每一行之间的间距
        layout?.minimumLineSpacing = paddingY
        
        //设置列表视图
        photoAssetCollectionView.dataSource = self
        photoAssetCollectionView.delegate = self
        photoAssetCollectionView.collectionViewLayout = layout!
        photoAssetCollectionView.allowsMultipleSelection = true
        
        //设置缩略图大小
        let scale: CGFloat = CGFloat(UIScreen.main.scale)
        let cellSize: CGSize = layout!.itemSize
        thumbnailSize = CGSize(width: (cellSize.width * scale), height: (cellSize.height * scale))
        
        //注册cell
        photoAssetCellID = "YCPhotoAssetCell"
        photoAssetCollectionView.register(UINib(nibName: photoAssetCellID!, bundle: nil), forCellWithReuseIdentifier: photoAssetCellID!)
        
        //注册footer
        photoAssetCollectionView.register(UINib(nibName: "YCPhotoAssetFooterView", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "YCPhotoAssetFooterView")
        
        //设置滑动手势
        panGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(pan(gestureRecognizer:)))
        panGestureRecognizer?.delegate = self
        panGestureRecognizer?.minimumNumberOfTouches = 1
        panGestureRecognizer?.maximumNumberOfTouches = 1
        self.view.addGestureRecognizer(panGestureRecognizer!)

        //监听设备旋转
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChange), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
        //监听系统相册变化
        PHPhotoLibrary.shared().register(self)
        
        //设置数据
        for asset in assetArr! {
            let model: YCPhotoAssetModel = YCPhotoAssetModel.init(asset: asset as! PHAsset)
            photoAssetArr?.append(model)
        }
        
        //设置列表视图显示到最底
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            if (self.photoAssetArr?.count)! > 0 {
                self.photoAssetCollectionView.scrollToItem(at: IndexPath.init(row: (self.photoAssetArr?.count)! - 1, section: 0), at: UICollectionViewScrollPosition.top, animated: false)
            }
        }

        //判断没有一个数据
        noDataBaseView.isHidden = photoAssetArr?.count == 0 ? false : true
    }
    
    //MARK: - UICollectionView代理
    //多少组
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //这组多少行
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoAssetArr!.count
    }
    
    //每行cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: YCPhotoAssetCell = collectionView.dequeueReusableCell(withReuseIdentifier: photoAssetCellID!, for: indexPath) as! YCPhotoAssetCell
        
        cell.photoAssetVC = self
        cell.refreshPhotoAsset(model:(photoAssetArr?[indexPath.row])!)
        
        return cell
    }
    
    //选中cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectItem(indexPath: indexPath)
    }

    //反选cell
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.selectItem(indexPath: indexPath)
    }
    
    //点击cell
    func selectItem(indexPath: IndexPath) {
        
        let model: YCPhotoAssetModel = photoAssetArr![indexPath.row]
        if model.isChecked! {
            checkedCount -= 1
            model.isChecked = false
        }
        else{
            checkedCount += 1
            //判断大于最多选择的个数
            if checkedCount > maxNum {
                var titleStr: String = ""
                if mediaType == PHAssetMediaType.unknown {
                    titleStr = String(format: "最多只能选择%zd项!", maxNum)
                }
                else if mediaType == PHAssetMediaType.image {
                    titleStr = String(format: "最多只能选择%d张照片!", maxNum)
                }
                else if mediaType == PHAssetMediaType.video {
                    titleStr = String(format: "最多只能选择%d部视频!", maxNum)
                }
                else if mediaType == PHAssetMediaType.audio {
                    titleStr = String(format: "最多只能选择%d首歌曲!", maxNum)
                }
                
                let alertVC: UIAlertController = UIAlertController.init(title: titleStr, message: nil, preferredStyle: UIAlertControllerStyle.alert)
                let alertAction: UIAlertAction = UIAlertAction.init(title: "我知道了", style: UIAlertActionStyle.default, handler: nil)
                
                alertVC.addAction(alertAction)
                self.present(alertVC, animated: true, completion: nil)
                
                checkedCount -= 1
                return
            }
            model.isChecked = true
        }
        //刷新这一行
        photoAssetCollectionView.reloadItems(at: [indexPath])
        //self.photoAssetCollectionView.reloadData()
        
        //设置标题
        if checkedCount == 0 {
            self.navigationItem.title = directoryTitle
        }
        else{
            if mediaType == PHAssetMediaType.unknown {
                self.title = String(format: "已选择%d项", checkedCount)
            }
            else if mediaType == PHAssetMediaType.image {
                self.title = String(format: "已选择%d张照片", checkedCount)
            }
            else if mediaType == PHAssetMediaType.video {
                self.title = String(format: "已选择%d部视频", checkedCount)
            }
            else if mediaType == PHAssetMediaType.audio {
                self.title = String(format: "已选择%d首歌曲", checkedCount)
            }
        }
    }
    
    //设置footer和header
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionFooter {
            let footerView: YCPhotoAssetFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "YCPhotoAssetFooterView", for: indexPath) as! YCPhotoAssetFooterView
          
            var numStr: String = ""
            let imageNum: Int = (fetchResult?.countOfAssets(with: PHAssetMediaType.image))!
            let videoNum: Int = (fetchResult?.countOfAssets(with: PHAssetMediaType.video))!
            let audioNum: Int = (fetchResult?.countOfAssets(with: PHAssetMediaType.audio))!
            
            if imageNum > 0 && videoNum == 0 && audioNum == 0 {
                numStr = String(format: "%d张照片", imageNum)
            }
            else if imageNum > 0 && videoNum > 0 && audioNum == 0 {
                numStr = String(format: "%d张照片、%d部视频", imageNum, videoNum)
            }
            else if imageNum > 0 && videoNum > 0 && audioNum > 0 {
                numStr = String(format: "%d张照片、%d部视频、%d首歌曲", imageNum, videoNum, audioNum)
            }
            else if imageNum == 0 && videoNum > 0 && audioNum > 0 {
                numStr = String(format: "%d部视频、%d首歌曲", videoNum, audioNum)
            }
            else if imageNum == 0 && videoNum > 0 && audioNum == 0 {
                numStr = String(format: "%d部视频", videoNum)
            }
            else if imageNum == 0 && videoNum == 0 && audioNum == 0 {
                numStr = ""
            }
            footerView.numLabel.text = numStr
            
            return footerView
        }
        return YCPhotoAssetFooterView()
    }
    
    //设置footer高度
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
   
        //计算集合视图的高度
        let SCREEN_WIDTH: CGFloat = UIScreen.main.bounds.size.width
        var h: CGFloat = 0.0
        let interfaceOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        
        if UIInterfaceOrientationIsPortrait(interfaceOrientation) {
            //print("是竖屏")
            let w: CGFloat = (SCREEN_WIDTH - 1.0 * (VERTICAL_COLS + 1)) / VERTICAL_COLS
            let nextRow: CGFloat = (photoAssetArr?.count)! % Int(VERTICAL_COLS) == 0 ? 0 : 1
            let row: CGFloat = CGFloat((photoAssetArr?.count)!) / VERTICAL_COLS + nextRow
            
            h = (w * row) + (row + 1)
        }
        else if UIInterfaceOrientationIsLandscape(interfaceOrientation) {
            //print("是横屏")
            let w: CGFloat = (SCREEN_WIDTH - 1.0 * (HORIZONTAL_COLS + 1)) / HORIZONTAL_COLS
            let nextRow: CGFloat = (photoAssetArr?.count)! % Int(HORIZONTAL_COLS) == 0 ? 0 : 1
            let row: CGFloat = CGFloat((photoAssetArr?.count)!) / HORIZONTAL_COLS + nextRow
            
            h = (w * row) + (row + 1)
        }
        
        let screenH: CGFloat = self.view.bounds.size.height - self.navigationController!.navigationBar.bounds.size.height - self.navigationController!.toolbar.bounds.size.height - 20
        
        if h < screenH {
            return CGSize(width: self.view.bounds.size.width, height: 0)
        }else{
            return CGSize(width: self.view.bounds.size.width, height: 40)
        }
    }
    
    //MARK: - 手势代理
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        //判断是滑动手势
        if self.panGestureRecognizer == gestureRecognizer {
            let beginPoint: CGPoint = (panGestureRecognizer?.location(in: self.view))!
            //小于等于44是右滑返回
            if beginPoint.x <= 44 {
                return false
            }
        }
        return true
    }
    
    //MARK: - 滑动多选
    @objc func pan(gestureRecognizer: UIPanGestureRecognizer) {
        
        let pointerX: CGFloat = gestureRecognizer.location(in: photoAssetCollectionView).x
        let pointerY: CGFloat = gestureRecognizer.location(in: photoAssetCollectionView).y
        
        for cell in photoAssetCollectionView.visibleCells {
            let cellSX: CGFloat = cell.frame.origin.x
            let cellEX: CGFloat = cell.frame.origin.x + cell.frame.size.width
            let cellSY: CGFloat = cell.frame.origin.y
            let cellEY: CGFloat = cell.frame.origin.y + cell.frame.size.height
            
            if pointerX >= cellSX && pointerX <= cellEX && pointerY >= cellSY && pointerY <= cellEY {
                
                let touchOverIndexPath: IndexPath? = photoAssetCollectionView.indexPath(for: cell)
                if lastIndexPath != touchOverIndexPath {
                    
                    if gestureRecognizer.state == UIGestureRecognizerState.changed {
                        if cell.isSelected {
                            self.collection(photoAssetCollectionView, deselectItemAt: touchOverIndexPath!)
                        }
                        else{
                            self.collection(photoAssetCollectionView, selectItemAt: touchOverIndexPath!)
                        }
                        lastIndexPath = touchOverIndexPath
                    }
                }
            }
            if gestureRecognizer.state == UIGestureRecognizerState.ended {
                lastIndexPath = nil
                photoAssetCollectionView.isScrollEnabled = true
            }
        }
    }

    //选中cell
    func collection(_ collectionView: UICollectionView, selectItemAt indexPath: IndexPath) {
        
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.init())
        self.collectionView(collectionView, didSelectItemAt: indexPath)
    }
    
    //反选cell
    func collection(_ collectionView: UICollectionView, deselectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
        self.collectionView(collectionView, didDeselectItemAt: indexPath)
    }
    
    //MARK: - 监听系统相册变化
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        let collectionChanges: PHFetchResultChangeDetails? = changeInstance.changeDetails(for: fetchResult as! PHFetchResult<PHObject>)
        if collectionChanges == nil {
            return
        }
        
        //必须主线程进行
        DispatchQueue.main.async {
            //清空上次的数据
            self.photoAssetArr?.removeAll()
            
            //重新设置数据
            self.fetchResult = collectionChanges?.fetchResultAfterChanges as! PHFetchResult<PHAsset>?
            let count: Int = (self.fetchResult?.count)!
            for i in 0 ..< count {
                let model: YCPhotoAssetModel = YCPhotoAssetModel.init(asset: self.fetchResult![i])
                self.photoAssetArr?.append(model)
            }
            
            //刷新数据
            self.photoAssetCollectionView.reloadData()
            
            //判断没有一个数据
            self.noDataBaseView.isHidden = self.photoAssetArr?.count == 0 ? false : true
        }
    }
    
    //MARK: - 监听设备方向
    @objc func deviceOrientationChange() {
        
        //计算cell的宽度
        let SCREEN_WIDTH: CGFloat = UIScreen.main.bounds.size.width
        var w: CGFloat = 0.0
        let interfaceOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        
        if UIInterfaceOrientationIsPortrait(interfaceOrientation) {
            //print("是竖屏")
            w = (SCREEN_WIDTH - 1.0 * (VERTICAL_COLS + 1)) / VERTICAL_COLS
        }
        else if UIInterfaceOrientationIsLandscape(interfaceOrientation) {
            //print("是横屏")
            w = (SCREEN_WIDTH - 1.0 * (HORIZONTAL_COLS + 1)) / HORIZONTAL_COLS
        }
        
        //设置每个格子的尺寸
        layout?.itemSize = CGSize(width: w, height: w)

        //设置缩略图大小
        let scale: CGFloat = CGFloat(UIScreen.main.scale)
        let cellSize: CGSize = layout!.itemSize
        thumbnailSize = CGSize(width: (cellSize.width * scale), height: (cellSize.height * scale))
        
        //刷新数据
        //self.photoAssetCollectionView.reloadData()
        self.photoAssetCollectionView.reloadSections(IndexSet.init(integer: 0))
    }
    
    //MARK: - 完成选择
    @objc func finish() {
        if checkedCount > 0 {
            var newAssetArr: Array = Array<PHAsset>()
            for model in photoAssetArr! {
                if model.isChecked! {
                    newAssetArr.append(model.asset!)
                }
            }
 
            //通知代理
            photoSelectorVC!.delegate?.finish?(photoSelectorVC: photoSelectorVC!, assetArr: newAssetArr)
        }
        self.dismiss(animated: true, completion: nil)
    }
}





