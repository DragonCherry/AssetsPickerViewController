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
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        defer {
            changingSize = nil
        }
        guard let collectionView = self.collectionView, let changingSize = self.changingSize else {
            return proposedContentOffset
        }
        logi("proposedContentOffset: \(proposedContentOffset)")
        let isPortrait = changingSize.height > changingSize.width
        let contentHeight = expectedContentHeight(isPortrait: isPortrait)
        let currentRatio = (collectionView.contentOffset.y + collectionView.bounds.size.height / 2) / collectionView.contentSize.height
        
        let futureOffsetY = contentHeight * currentRatio - changingSize.height / 2
        
        log("expected content height: \(contentHeight) -> ")
        
        return CGPoint(x: 0, y: futureOffsetY)
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
}
