import UIKit
import PureLayout

open class AssetsPhotoHeaderView: UICollectionReusableView {
    
    private var didSetupConstraints: Bool = false
    private let dateFormatter = DateFormatter()
    
    private let locationLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textAlignment = .left
        label.font = UIFont.systemFont(forStyle: .body, weight: .semibold)
        label.textColor = .darkText
        label.text = ""
        return label
    }()
    
    private let subLocationLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textAlignment = .left
        label.font = UIFont.systemFont(forStyle: .body)
        label.textColor = .gray
        label.text = ""
        return label
    }()
    
    private let subView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        return view
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
        subView.layoutMargins = UIEdgeInsets(top: 15, left: 15, bottom: 10, right: 0)
        subView.addSubview(locationLabel)
        subView.addSubview(subLocationLabel)
        addSubview(subView)
    }
    
    open override func updateConstraints() {
        subView.autoPinEdgesToSuperviewEdges()
        locationLabel.autoPinEdge(toSuperviewMargin: .left)
        locationLabel.autoPinEdge(toSuperviewMargin: .top)
        subLocationLabel.autoPinEdge(toSuperviewMargin: .left)
        subLocationLabel.autoPinEdge(.top, to: .bottom, of: locationLabel)

//        let view = UIView()
//        subView.insertSubview(view, at: 0)
//        view.autoPinEdgesToSuperviewMargins()
//        view.insertSubview(subLocationLabel, at: 0)
//        if let subLabel = subLocationLabel.text, !subLabel.isEmpty {
//            view.insertSubview(subLocationLabel, at: 1)
//        }
        super.updateConstraints()
    }
    
    open func set(location: String?, subLocation: [String], date: Date?) {
        if location != nil {
            locationLabel.text = location!
        } else if date != nil && subLocation.count == 0 {
            dateFormatter.dateStyle = .long
            locationLabel.text = dateFormatter.string(from: date!)
        }
        
        if location != nil && date != nil && subLocation.count > 0 {
            dateFormatter.dateStyle = .medium
            subLocationLabel.text = "\(dateFormatter.string(from: date!))  ·  \(subLocation[0])"
        } else if subLocation.count > 0 {
            subLocationLabel.text = subLocation[0]
        } else {
            subLocationLabel.text = ""
            locationLabel.text = locationLabel.text!
        }
    }
}
