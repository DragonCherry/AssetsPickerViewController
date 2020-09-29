//
//  AssetsPhotoLayout.swift
//  Pods
//
//  Created by DragonCherry on 5/18/17.
//
//

import UIKit

open class AssetsPhotoLayout: UICollectionViewFlowLayout {
    
    open var translatedOffset: CGPoint?
    fileprivate var pickerConfig: AssetsPickerConfig
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(pickerConfig: AssetsPickerConfig) {
        self.pickerConfig = pickerConfig
        super.init()
    }
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        return targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let translatedOffset = self.translatedOffset {
            return translatedOffset
        } else {
            return proposedContentOffset
        }
    }
}

extension AssetsPhotoLayout {
    
    open func expectedContentHeight(forViewSize size: CGSize, isPortrait: Bool) -> CGFloat {
        guard let fetchResult = AssetsManager.shared.fetchResult else { return 0.0 }
        var rows = fetchResult.count / (isPortrait ? pickerConfig.assetPortraitColumnCount : pickerConfig.assetLandscapeColumnCount)
        let remainder = fetchResult.count % (isPortrait ? pickerConfig.assetPortraitColumnCount : pickerConfig.assetLandscapeColumnCount)
        rows += remainder > 0 ? 1 : 0
        
        let cellSize = isPortrait ? pickerConfig.assetPortraitCellSize(forViewSize: UIScreen.main.portraitContentSize) : pickerConfig.assetLandscapeCellSize(forViewSize: UIScreen.main.landscapeContentSize)
        let lineSpace = isPortrait ? pickerConfig.assetPortraitLineSpace : pickerConfig.assetLandscapeLineSpace
        let contentHeight = CGFloat(rows) * cellSize.height + (CGFloat(max(rows - 1, 0)) * lineSpace)
        let bottomHeight = cellSize.height * 2/3 + UIScreen.safeAreaInsets(isPortrait: isPortrait).bottom
        
        return contentHeight + bottomHeight
    }
    
    private func offsetRatio(collectionView: UICollectionView, offset: CGPoint, contentSize: CGSize, isPortrait: Bool) -> CGFloat {
        return (offset.y > 0 ? offset.y : 0) / ((contentSize.height + UIScreen.safeAreaInsets(isPortrait: isPortrait).bottom) - collectionView.bounds.height)
    }
    
    open func translateOffset(forChangingSize size: CGSize, currentOffset: CGPoint) -> CGPoint? {
        guard let collectionView = self.collectionView else {
            return nil
        }
        let isPortraitFuture = size.height > size.width
        let isPortraitCurrent = collectionView.bounds.size.height > collectionView.bounds.size.width
        let contentHeight = expectedContentHeight(forViewSize: size, isPortrait: isPortraitFuture)
        let currentRatio = offsetRatio(collectionView: collectionView, offset: currentOffset, contentSize: collectionView.contentSize, isPortrait: isPortraitCurrent)
        logi("currentRatio = \(currentRatio)")
        var futureOffsetY = (contentHeight - size.height) * currentRatio
        
        if currentOffset.y < 0 {
            let insetRatio = (-currentOffset.y) / UIScreen.safeAreaInsets(isPortrait: isPortraitCurrent).top
            let insetDiff = UIScreen.safeAreaInsets(isPortrait: isPortraitFuture).top * insetRatio
            futureOffsetY -= insetDiff
        }
        
        return CGPoint(x: 0, y: futureOffsetY)
    }
}
