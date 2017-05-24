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

    open var translatedOffset: CGPoint?
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        return targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let translatedOffset = self.translatedOffset {
//            logi("returning translatedOffset: \(translatedOffset)")
            return translatedOffset
        } else {
//            logi("returning proposedContentOffset: \(proposedContentOffset)")
            return proposedContentOffset
        }
    }
}

extension AssetsPhotoLayout {
    
    open func translateOffset(forChangingSize size: CGSize, currentOffset: CGPoint) -> CGPoint? {
        guard let collectionView = self.collectionView else {
            return nil
        }
        let isPortrait = size.height > size.width
        let contentHeight = expectedContentHeight(isPortrait: isPortrait)
        let currentRatio = offsetRatio(collectionView: collectionView, offset: currentOffset, contentSize: collectionView.contentSize, isPortrait: isPortrait)
        
        let futureOffsetY = (contentHeight - size.height) * currentRatio
        return CGPoint(x: 0, y: futureOffsetY)
    }
    
    open func expectedContentHeight(isPortrait: Bool) -> CGFloat {
        var rows = AssetsManager.shared.photoArray.count / (isPortrait ? PhotoAttributes.portraitColumnCount : PhotoAttributes.landscapeColumnCount)
        let remainder = AssetsManager.shared.photoArray.count % (isPortrait ? PhotoAttributes.portraitColumnCount : PhotoAttributes.landscapeColumnCount)
        rows += remainder > 0 ? 1 : 0
        
        let cellSize = isPortrait ? PhotoAttributes.portraitCellSize : PhotoAttributes.landscapeCellSize
        let lineSpace = isPortrait ? PhotoAttributes.portraitLineSpace : PhotoAttributes.landscapeLineSpace
        let contentHeight = CGFloat(rows) * cellSize.height + (CGFloat(max(rows - 1, 0)) * lineSpace)
        
        return contentHeight
    }
    
    private func offsetRatio(collectionView: UICollectionView, offset: CGPoint, contentSize: CGSize, isPortrait: Bool) -> CGFloat {
        let inset: CGFloat = 0
        let ratio = (offset.y + inset) / (contentSize.height - collectionView.bounds.height + inset)
        return ratio
    }
}
