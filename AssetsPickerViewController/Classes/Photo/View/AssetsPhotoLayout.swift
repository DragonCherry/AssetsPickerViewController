//
//  AssetsPhotoLayout.swift
//  Pods
//
//  Created by DragonCherry on 5/18/17.
//
//

import UIKit
import TinyLog

open class AssetsPhotoLayout: UICollectionViewFlowLayout {
    
    open var changingSize: CGSize?
    open var currentOffset: CGPoint?
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        defer {
            changingSize = nil
            currentOffset = nil
        }
        guard let collectionView = self.collectionView, let changingSize = self.changingSize, let currentOffset = self.currentOffset else {
            return proposedContentOffset
        }
        logi("proposedContentOffset: \(proposedContentOffset)")
        let isPortrait = changingSize.height > changingSize.width
        let contentHeight = expectedContentHeight(isPortrait: isPortrait)
        let currentRatio = offsetRatio(collectionView: collectionView, offset: currentOffset, contentSize: collectionView.contentSize, isPortrait: isPortrait)
        
        let futureOffsetY = (contentHeight - changingSize.height) * currentRatio
        
        logi("modified offset: \(futureOffsetY)")
        
        return CGPoint(x: 0, y: futureOffsetY)
    }
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        logi("proposedContentOffset: \(proposedContentOffset)")
        return proposedContentOffset
    }
    
    private func expectedContentHeight(isPortrait: Bool) -> CGFloat {
        var rows = AssetsManager.shared.photoArray.count / (isPortrait ? PhotoAttributes.portraitColumnCount : PhotoAttributes.landscapeColumnCount)
        let remainder = AssetsManager.shared.photoArray.count % (isPortrait ? PhotoAttributes.portraitColumnCount : PhotoAttributes.landscapeColumnCount)
        rows += remainder > 0 ? 1 : 0
        
        let cellSize = isPortrait ? PhotoAttributes.portraitCellSize : PhotoAttributes.landscapeCellSize
        let lineSpace = isPortrait ? PhotoAttributes.portraitLineSpace : PhotoAttributes.landscapeLineSpace
        let contentHeight = CGFloat(rows) * cellSize.height + (CGFloat(max(rows - 1, 0)) * lineSpace)
        
        return contentHeight
    }
    
    private func offsetRatio(collectionView: UICollectionView, offset: CGPoint, contentSize: CGSize, isPortrait: Bool) -> CGFloat {
//        let inset = CGFloat(isPortrait ? 65 : 33)
        let inset: CGFloat = 0
        let ratio = (offset.y + inset) / (contentSize.height - collectionView.bounds.height + inset)
        return ratio
    }
}
