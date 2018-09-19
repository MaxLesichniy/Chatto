/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit
import Chatto

public protocol TextBubbleViewStyleProtocol: BaseBubbleViewStyleProtocol {
//    func bubbleImage(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage
//    func bubbleImageBorder(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage?
    func textFont(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIFont
    func textColor(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIColor
//    func textInsets(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIEdgeInsets
}

public final class TextBubbleView<MessageViewModelT: TextMessageViewModelProtocol>: BaseBubbleView<MessageViewModelT, UITextView, TextBubbleViewDefaultStyle> {

    public override var viewContext: ViewContext {
        didSet {
            if self.viewContext == .sizing {
                self.contentView.dataDetectorTypes = UIDataDetectorTypes()
                self.contentView.isSelectable = false
            } else {
                self.contentView.dataDetectorTypes = .all
                self.contentView.isSelectable = true
            }
        }
    }

    public override var canCalculateSizeInBackground: Bool { return false }
    
//    public var bubbleViewStyle: TextBubbleViewStyleProtocol! {
//        didSet {
//            self.baseBubbleViewStyle = bubbleViewStyle
//            self.updateViews()
//        }
//    }

    public var selected: Bool = false {
        didSet {
            if self.selected != oldValue {
                self.updateViews(with: bubbleViewStyle, viewModel: messageViewModel)
            }
        }
    }

    override init(frame: CGRect) {
        let textView = ChatMessageTextView()
        UIView.performWithoutAnimation({ () -> Void in // fixes iOS 8 blinking when cell appears
            textView.backgroundColor = UIColor.clear
        })
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = .all
        textView.scrollsToTop = false
        textView.isScrollEnabled = false
        textView.bounces = false
        textView.bouncesZoom = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isExclusiveTouch = true
        textView.textContainer.lineFragmentPadding = 0
        super.init(frame: frame, contentView: textView)
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        
    }

    public override func updateViews(with style: TextBubbleViewDefaultStyle, viewModel: MessageViewModelT) {
        if self.viewContext == .sizing { return }
        self.updateTextView()
    }
    
//    public override func updateViews() {
//        super.updateViews()
//
//        if self.viewContext == .sizing { return }
//        if isUpdating { return }
////        guard let style = self.bubbleViewStyle, let viewModel = self.messageViewModel else { return }
//
//        self.updateTextView()
////        let bubbleImage = style.bubbleImage(viewModel: self.textMessageViewModel, isSelected: self.selected)
////        let borderImage = style.bubbleImageBorder(viewModel: self.textMessageViewModel, isSelected: self.selected)
////        if self.bubbleImageView.image != bubbleImage { self.bubbleImageView.image = bubbleImage }
////        if self.borderImageView.image != borderImage { self.borderImageView.image = borderImage }
//    }

    private func updateTextView() {
        guard let style = self.bubbleViewStyle, let viewModel = self.messageViewModel else { return }

        let font = style.textFont(viewModel: viewModel, isSelected: self.selected)
        let textColor = style.textColor(viewModel: viewModel, isSelected: self.selected)

        var needsToUpdateText = false

        if self.contentView.font != font {
            self.contentView.font = font
            needsToUpdateText = true
        }

        if self.contentView.textColor != textColor {
            self.contentView.textColor = textColor
            self.contentView.linkTextAttributes = [
                NSAttributedStringKey.foregroundColor.rawValue: textColor,
                NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue
            ]
            needsToUpdateText = true
        }

        if needsToUpdateText || self.contentView.text != viewModel.text {
            self.contentView.text = viewModel.text
        }

//        let textInsets = style.contentInsets(viewModel: viewModel, isSelected: self.selected)
        if self.contentView.textContainerInset != .zero { self.contentView.textContainerInset = .zero }
    }
    
    public override func contentViewSizeThatFits(_ size: CGSize) -> CGSize {
        return self.calculateTextBubbleLayout(preferredMaxLayoutWidth: size.width).size
    }

//    public override func contentViewSize() -> CGSize {
//        return self.calculateTextBubbleLayout(preferredMaxLayoutWidth: size.width).size
//    }
    
//    public override func sizeThatFits(_ size: CGSize) -> CGSize {
//        return self.calculateTextBubbleLayout(preferredMaxLayoutWidth: size.width).size
//    }

    // MARK: Layout
    
//    public override func layoutSubviews() {
//        super.layoutSubviews()
//        let layout = self.calculateTextBubbleLayout(preferredMaxLayoutWidth: self.preferredMaxLayoutWidth)
//        self.contentView.bma_rect = layout.textFrame
//    }

    public var layoutCache: NSCache<AnyObject, AnyObject>!
    private func calculateTextBubbleLayout(preferredMaxLayoutWidth: CGFloat) -> TextBubbleLayoutModel {
        let layoutContext = TextBubbleLayoutModel.LayoutContext(
            text: messageViewModel.text,
            font: bubbleViewStyle.textFont(viewModel: messageViewModel, isSelected: selected),
            textInsets: bubbleViewStyle.contentInsets(viewModel: messageViewModel, isSelected: selected),
            preferredMaxLayoutWidth: preferredMaxLayoutWidth
        )

        if let layoutModel = self.layoutCache.object(forKey: layoutContext.hashValue as AnyObject) as? TextBubbleLayoutModel, layoutModel.layoutContext == layoutContext {
            return layoutModel
        }

        let layoutModel = TextBubbleLayoutModel(layoutContext: layoutContext)
        layoutModel.calculateLayout()

        self.layoutCache.setObject(layoutModel, forKey: layoutContext.hashValue as AnyObject)
        return layoutModel
    }

}

private final class TextBubbleLayoutModel {
    let layoutContext: LayoutContext
    var textFrame: CGRect = CGRect.zero
    var bubbleFrame: CGRect = CGRect.zero
    var size: CGSize = CGSize.zero

    init(layoutContext: LayoutContext) {
        self.layoutContext = layoutContext
    }

    struct LayoutContext: Equatable, Hashable {
        let text: String
        let font: UIFont
        let textInsets: UIEdgeInsets
        let preferredMaxLayoutWidth: CGFloat

        var hashValue: Int {
            return Chatto.bma_combine(hashes: [self.text.hashValue, self.textInsets.bma_hashValue, self.preferredMaxLayoutWidth.hashValue, self.font.hashValue])
        }

        static func == (lhs: TextBubbleLayoutModel.LayoutContext, rhs: TextBubbleLayoutModel.LayoutContext) -> Bool {
            let lhsValues = (lhs.text, lhs.textInsets, lhs.font, lhs.preferredMaxLayoutWidth)
            let rhsValues = (rhs.text, rhs.textInsets, rhs.font, rhs.preferredMaxLayoutWidth)
            return lhsValues == rhsValues
        }
    }

    func calculateLayout() {
//        let textHorizontalInset = self.layoutContext.textInsets.bma_horziontalInset
        let maxTextWidth = self.layoutContext.preferredMaxLayoutWidth// - textHorizontalInset
        let textSize = self.textSizeThatFitsWidth(maxTextWidth)
        let bubbleSize = textSize//.bma_outsetBy(dx: textHorizontalInset, dy: self.layoutContext.textInsets.bma_verticalInset)
        self.bubbleFrame = CGRect(origin: CGPoint.zero, size: bubbleSize)
        self.textFrame = self.bubbleFrame
        self.size = bubbleSize
    }

    private func textSizeThatFitsWidth(_ width: CGFloat) -> CGSize {
        let textContainer: NSTextContainer = {
            let size = CGSize(width: width, height: .greatestFiniteMagnitude)
            let container = NSTextContainer(size: size)
            container.lineFragmentPadding = 0
            return container
        }()

        let textStorage = self.replicateUITextViewNSTextStorage()
        let layoutManager: NSLayoutManager = {
            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            return layoutManager
        }()

        let rect = layoutManager.usedRect(for: textContainer)
        return rect.size.bma_round()
    }

    private func replicateUITextViewNSTextStorage() -> NSTextStorage {
        // See https://github.com/badoo/Chatto/issues/129
        return NSTextStorage(string: self.layoutContext.text, attributes: [
            NSAttributedStringKey.font: self.layoutContext.font,
            NSAttributedStringKey(rawValue: "NSOriginalFont"): self.layoutContext.font
        ])
    }
}

/// UITextView with hacks to avoid selection, loupe, define...
private final class ChatMessageTextView: UITextView {

    override var canBecomeFirstResponder: Bool {
        return false
    }

    // See https://github.com/badoo/Chatto/issues/363
    override var gestureRecognizers: [UIGestureRecognizer]? {
        set {
            super.gestureRecognizers = newValue
        }
        get {
            return super.gestureRecognizers?.filter({ (gestureRecognizer) -> Bool in
                return type(of: gestureRecognizer) == UILongPressGestureRecognizer.self && gestureRecognizer.delaysTouchesEnded
            })
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override var selectedRange: NSRange {
        get {
            return NSRange(location: 0, length: 0)
        }
        set {
            // Part of the heaviest stack trace when scrolling (when updating text)
            // See https://github.com/badoo/Chatto/pull/144
        }
    }

    override var contentOffset: CGPoint {
        get {
            return .zero
        }
        set {
            // Part of the heaviest stack trace when scrolling (when bounds are set)
            // See https://github.com/badoo/Chatto/pull/144
        }
    }
}
