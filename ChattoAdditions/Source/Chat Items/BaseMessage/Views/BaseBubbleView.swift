//
//  BaseBubbleView.swift
//  ChattoAdditions
//
//  Created by Max Lesichniy on 18.09.2018.
//

import Foundation
import UIKit

public protocol BaseBubbleViewStyleProtocol {
    func maskingImage(viewModel: DecoratedMessageViewModelProtocol) -> UIImage
    func borderImage(viewModel: DecoratedMessageViewModelProtocol) -> UIImage?
    func attributedStringForSenderName(viewModel: DecoratedMessageViewModelProtocol) -> NSAttributedString?
    func isShowUserName(viewModel: DecoratedMessageViewModelProtocol) -> Bool
    func contentInsets(viewModel: DecoratedMessageViewModelProtocol, isSelected: Bool) -> UIEdgeInsets
    func backgroundColor(viewModel: DecoratedMessageViewModelProtocol, isSelected: Bool) -> UIColor
}

open class BaseBubbleDefaultStyle: BaseBubbleViewStyleProtocol {
    
    public struct BubbleMasks {
        public let incomingTail: () -> UIImage
        public let incomingNoTail: () -> UIImage
        public let outgoingTail: () -> UIImage
        public let outgoingNoTail: () -> UIImage
        public let tailWidth: CGFloat
        public init(
            incomingTail: @autoclosure @escaping () -> UIImage,
            incomingNoTail: @autoclosure @escaping () -> UIImage,
            outgoingTail: @autoclosure @escaping () -> UIImage,
            outgoingNoTail: @autoclosure @escaping () -> UIImage,
            tailWidth: CGFloat) {
            self.incomingTail = incomingTail
            self.incomingNoTail = incomingNoTail
            self.outgoingTail = outgoingTail
            self.outgoingNoTail = outgoingNoTail
            self.tailWidth = tailWidth
        }
    }
    
    let baseStyle: BaseMessageCollectionViewCellDefaultStyle
    let bubbleMasks: BubbleMasks
    let incomingInsets: UIEdgeInsets
    let outgoingInsets: UIEdgeInsets
    
    lazy private var maskImageIncomingTail: UIImage = self.bubbleMasks.incomingTail()
    lazy private var maskImageIncomingNoTail: UIImage = self.bubbleMasks.incomingNoTail()
    lazy private var maskImageOutgoingTail: UIImage = self.bubbleMasks.outgoingTail()
    lazy private var maskImageOutgoingNoTail: UIImage = self.bubbleMasks.outgoingNoTail()
    
    
    public init(bubbleMasks: BubbleMasks = BaseBubbleDefaultStyle.createDefaultBubbleMasks(),
                baseStyle: BaseMessageCollectionViewCellDefaultStyle = BaseMessageCollectionViewCellDefaultStyle(),
                incomingInsets: UIEdgeInsets,
                outgoingInsets: UIEdgeInsets) {
        self.bubbleMasks = bubbleMasks
        self.baseStyle = baseStyle
        self.incomingInsets = incomingInsets
        self.outgoingInsets = outgoingInsets
    }
    
    open func maskingImage(viewModel: DecoratedMessageViewModelProtocol) -> UIImage {
        switch (viewModel.isIncoming, viewModel.decorationAttributes.isShowingTail) {
        case (true, true):
            return self.maskImageIncomingTail
        case (true, false):
            return self.maskImageIncomingNoTail
        case (false, true):
            return self.maskImageOutgoingTail
        case (false, false):
            return self.maskImageOutgoingNoTail
        }
    }
    
    open func borderImage(viewModel: DecoratedMessageViewModelProtocol) -> UIImage? {
        return self.baseStyle.borderImage(viewModel: viewModel)
    }
    
    open func attributedStringForSenderName(viewModel: DecoratedMessageViewModelProtocol) -> NSAttributedString? {
        let font = baseStyle.senderNameStyle.font
        let color = baseStyle.senderNameStyle.textColor
        return viewModel.senderName.map { NSAttributedString(string: $0, attributes: [.font: font, .foregroundColor: color]) }
    }
    
    open func isShowUserName(viewModel: DecoratedMessageViewModelProtocol) -> Bool {
        return baseStyle.senderNameStyle.isHidden == false
    }
    
    public func contentInsets(viewModel: DecoratedMessageViewModelProtocol, isSelected: Bool) -> UIEdgeInsets {
        return viewModel.isIncoming ? incomingInsets : outgoingInsets
    }
    
    public func backgroundColor(viewModel: DecoratedMessageViewModelProtocol, isSelected: Bool) -> UIColor {
        return viewModel.isIncoming ? baseStyle.baseColorIncoming : baseStyle.baseColorOutgoing
    }
    
    // defaults
    
    static public func createDefaultBubbleMasks() -> BubbleMasks {
        return BubbleMasks(
            incomingTail: UIImage(named: "bubble-incoming-tail", in: Bundle(for: BaseBubbleDefaultStyle.self), compatibleWith: nil)!,
            incomingNoTail: UIImage(named: "bubble-incoming", in: Bundle(for: BaseBubbleDefaultStyle.self), compatibleWith: nil)!,
            outgoingTail: UIImage(named: "bubble-outgoing-tail", in: Bundle(for: BaseBubbleDefaultStyle.self), compatibleWith: nil)!,
            outgoingNoTail: UIImage(named: "bubble-outgoing", in: Bundle(for: BaseBubbleDefaultStyle.self), compatibleWith: nil)!,
            tailWidth: 6
        )
    }
    
}

open class BaseBubbleView<MessageViewModelT: DecoratedMessageViewModelProtocol, ContentViewT: UIView, StyleT: BaseBubbleViewStyleProtocol>: UIView, MaximumLayoutWidthSpecificable, BackgroundSizingQueryable {
    
    open var canCalculateSizeInBackground: Bool { return false }
    
    open var viewContext: ViewContext = .normal
    open var preferredMaxLayoutWidth: CGFloat = 0
    open var animationDuration: CFTimeInterval = 0.33
    
    fileprivate(set) var stackView: StackableView = StackableView(views: [], anchoredAt: .top)
    fileprivate(set) var maskImageView: UIImageView = UIImageView()
    private lazy var borderView = UIImageView()
    private lazy var senderNameLabel = UILabel()
    
    public var topView: UIView? {
        willSet {
            topView?.removeFromSuperview()
        }
        didSet {
            topView.map { stackView.insertSubview($0, belowSubview: contentView)}
        }
    }
    public var contentView: ContentViewT!
    public var bottomView: UIView? {
        willSet {
            bottomView?.removeFromSuperview()
        }
        didSet {
            bottomView.map { stackView.insertSubview($0, aboveSubview: contentView)}
        }
    }
    
    open override var backgroundColor: UIColor? {
        set {
            stackView.backgroundColor = newValue
            super.backgroundColor = .clear
        }
        get {
            return stackView.backgroundColor
        }
    }
    
    // MARK: - Models
    
    open var messageViewModel: MessageViewModelT! {
        didSet {
            updateViews()
        }
    }
    
    open var bubbleViewStyle: StyleT! {
        didSet {
            updateViews()
        }
    }
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    public init(frame: CGRect, contentView: ContentViewT) {
        self.contentView = contentView
        super.init(frame: frame)
        self.commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        autoresizesSubviews = false
        stackView.mask = maskImageView
        addSubview(stackView)
        addSubview(borderView)
        topView.map { stackView.addSubview($0) }
        stackView.addSubview(contentView)
        bottomView.map { stackView.addSubview($0) }
    }
    
    // MARK: - Views
    
    public private(set) var isUpdating: Bool = false
    open func performBatchUpdates(_ updateClosure: @escaping () -> Void, animated: Bool, completion: (() -> Void)?) {
        self.isUpdating = true
        let updateAndRefreshViews = {
            updateClosure()
            self.isUpdating = false
            self.updateViews()
            if animated {
                self.layoutIfNeeded()
            }
        }
        if animated {
            UIView.animate(withDuration: self.animationDuration,
                           animations: updateAndRefreshViews,
                           completion: { (_) -> Void in
                completion?()
            })
        } else {
            updateAndRefreshViews()
        }
    }
    
    open func updateViews(with style: StyleT, viewModel: MessageViewModelT) {
        
    }
    
    fileprivate func updateViews() {
        guard let viewModel = messageViewModel, let style = self.bubbleViewStyle else { return }
        if isUpdating { return }
        
        stackView.contentInset = style.contentInsets(viewModel: viewModel, isSelected: false)
        stackView.alignment = viewModel.isIncoming ? .left : .right
        
        if let attrText = style.attributedStringForSenderName(viewModel: viewModel),
            style.isShowUserName(viewModel: viewModel) {
            senderNameLabel.attributedText = attrText
            if senderNameLabel.superview == nil {
                topView = senderNameLabel
            }
        } else {
            topView = nil
        }
        
        if self.viewContext == .normal {
            backgroundColor = style.backgroundColor(viewModel: viewModel, isSelected: false)
            borderView.image = style.borderImage(viewModel: viewModel)
            maskImageView.image = style.maskingImage(viewModel: viewModel)
        }

        updateViews(with: style, viewModel: viewModel)
        
        self.setNeedsLayout()
    }
    
    open func contentViewSizeThatFits(_ size: CGSize) -> CGSize {
        return .zero
    }
    
    
    // MARK: Layout
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let topViewSize = topView?.sizeThatFits(size) ?? .zero
        let contentViewSize = contentViewSizeThatFits(size)
        let bottomViewSize = bottomView?.sizeThatFits(size) ?? .zero
        let contentInsets = bubbleViewStyle?.contentInsets(viewModel: messageViewModel, isSelected: false) ?? .zero
        
        var resultSize = contentViewSize
        resultSize.height += topViewSize.height + bottomViewSize.height + contentInsets.bma_verticalInset
        resultSize.width = max(resultSize.width, max(topViewSize.width, bottomViewSize.width)) + contentInsets.bma_horziontalInset

        return resultSize
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds
        borderView.frame = bounds
        maskImageView.frame = bounds
    }
        
}
