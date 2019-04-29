//
//  AssetsAlbumHeaderView.swift
//  Pods
//
//  Created by DragonCherry on 5/18/17.
//
//

import UIKit

open class AssetsAlbumHeaderView: UICollectionReusableView {
    
    internal lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(rgbHex: 0x8C8C91)
        label.font = UIFont.systemFont(forStyle: .title3)
        label.text = String(key: "Title_Section_MyAlbums")
        return label
    }()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
