//
//  StackableView.swift
//  ChattoAdditions
//
//  Created by Max Lesichniy on 18.09.2018.
//

import Foundation
import UIKit

public protocol StackableViewDelegate: class {
    func stackableViewContainer(_ stackableViewContainer: StackableView, didAddSubview: UIView)
    func stackableViewContainer(_ stackableViewContainer: StackableView, willRemoveSubview: UIView)
}


public class StackableView: UIView {
    
    weak var delegate: StackableViewDelegate?
    
    /// The inset of the contents of the `StackableViewContainer`.
    /// For internal use only.
    var contentInset: UIEdgeInsets = .zero
    
    fileprivate(set) var anchorPoint: StackableViewContainerAnchorPoint
    var alignment: Alignment = .left {
        didSet {
            setNeedsLayout()
        }
    }
    
    enum StackableViewContainerAnchorPoint: Int {
        case top, bottom
    }

    enum Alignment {
        case left, right
    }
    
    init(views: [UIView], anchoredAt point: StackableViewContainerAnchorPoint) {
        self.anchorPoint = point
        super.init(frame: .zero)
        
        for view in views {
            self.addSubview(view)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.computeSize(for: self.frame.size, applySizingLayout: true)
    }
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.computeSize(for: size, applySizingLayout: false)
    }
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize, applySizingLayout: Bool) -> CGSize {
        var yOffset: CGFloat = 0
        let xOffset: CGFloat = self.contentInset.left
        var constrainedInsetSize = constrainedSize
        constrainedInsetSize.width -= (self.contentInset.left + self.contentInset.right)
        
        let subviews = (self.anchorPoint == .top) ? self.subviews : self.subviews.reversed()
        for subview in subviews {
            let size = subview.sizeThatFits(constrainedInsetSize)
            var frame: CGRect
            
            if yOffset == 0 && size.height > 0 {
                yOffset = self.contentInset.top
            }
            
            // special cases
            if subview is UIToolbar || subview is UINavigationBar {
                frame = CGRect(x: xOffset, y: yOffset, width: constrainedInsetSize.width, height: size.height)
            } else {
//                switch alignment {
//                case .left:
                    frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: size)
//                case .right:
//                    frame = CGRect(origin: CGPoint(x: constrainedInsetSize.width - size.width, y: yOffset), size: size)
//                }
            }
            
            
            yOffset += frame.size.height
            
            if applySizingLayout {
                subview.frame = frame
                subview.setNeedsLayout()
                subview.layoutIfNeeded()
            }
        }
        
        if (yOffset - self.contentInset.top) > 0 {
            yOffset += self.contentInset.bottom
        }
        
        return CGSize(width: constrainedSize.width, height: yOffset)
    }
    
    // MARK: - StackableViewContainerDelegate
    override public func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        self.delegate?.stackableViewContainer(self, didAddSubview: subview)
    }
    
    override public func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        self.delegate?.stackableViewContainer(self, willRemoveSubview: subview)
    }
    
}

