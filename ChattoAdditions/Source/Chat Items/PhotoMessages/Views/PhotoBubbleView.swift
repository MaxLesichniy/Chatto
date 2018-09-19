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

public protocol PhotoBubbleViewStyleProtocol: BaseBubbleViewStyleProtocol {
    func placeholderBackgroundImage(viewModel: PhotoMessageViewModelProtocol) -> UIImage
    func placeholderIconImage(viewModel: PhotoMessageViewModelProtocol) -> UIImage
    func placeholderIconTintColor(viewModel: PhotoMessageViewModelProtocol) -> UIColor
    func tailWidth(viewModel: PhotoMessageViewModelProtocol) -> CGFloat
    func bubbleSize(viewModel: PhotoMessageViewModelProtocol) -> CGSize
    func progressIndicatorColor(viewModel: PhotoMessageViewModelProtocol) -> UIColor
    func overlayColor(viewModel: PhotoMessageViewModelProtocol) -> UIColor?
}

open class PhotoContentView: UIView {
    
    public private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.autoresizingMask = UIViewAutoresizing()
        imageView.clipsToBounds = true
        imageView.autoresizesSubviews = false
        imageView.autoresizingMask = UIViewAutoresizing()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    public private(set) lazy var overlayView: UIView = {
        let view = UIView()
        return view
    }()
    
    public private(set) var progressIndicatorView: CircleProgressIndicatorView = {
        return CircleProgressIndicatorView(size: CGSize(width: 33, height: 33))
    }()
    
    public private(set) var placeholderIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.autoresizingMask = UIViewAutoresizing()
        return imageView
    }()
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.autoresizesSubviews = false
        self.addSubview(self.imageView)
        self.addSubview(self.placeholderIconView)
        self.addSubview(self.progressIndicatorView)
    }
    
}

open class PhotoBubbleView<MessageViewModelT: PhotoMessageViewModelProtocol>: BaseBubbleView<MessageViewModelT, PhotoContentView, PhotoBubbleViewDefaultStyle> {

    public override init(frame: CGRect) {
        super.init(frame: frame, contentView: PhotoContentView(frame: .zero))
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        
    }

//    public var bubbleViewStyle: PhotoBubbleViewStyleProtocol! {
//        didSet {
//            self.bubbleViewStyle = bubbleViewStyle
//            self.updateViews()
//        }
//    }

    open override func updateViews(with style: PhotoBubbleViewDefaultStyle, viewModel: MessageViewModelT) {
        if viewContext == .sizing { return }
        self.updateProgressIndicator()
        self.updateImages()
    }
    
    private func updateProgressIndicator() {
        let transferStatus = self.messageViewModel.transferStatus.value
        let transferProgress = self.messageViewModel.transferProgress.value
        self.contentView.progressIndicatorView.isHidden = [TransferStatus.idle, TransferStatus.success, TransferStatus.failed].contains(self.messageViewModel.transferStatus.value)
        self.contentView.progressIndicatorView.progressLineColor = self.bubbleViewStyle.progressIndicatorColor(viewModel: self.messageViewModel)
        self.contentView.progressIndicatorView.progressLineWidth = 1
        self.contentView.progressIndicatorView.setProgress(CGFloat(transferProgress))

        switch transferStatus {
        case .idle, .success, .failed:

            break
        case .transfering:
            switch transferProgress {
            case 0:
                if self.contentView.progressIndicatorView.progressStatus != .starting { self.contentView.progressIndicatorView.progressStatus = .starting }
            case 1:
                if self.contentView.progressIndicatorView.progressStatus != .completed { self.contentView.progressIndicatorView.progressStatus = .completed }
            default:
                if self.contentView.progressIndicatorView.progressStatus != .inProgress { self.contentView.progressIndicatorView.progressStatus = .inProgress }
            }
        }
    }

    private func updateImages() {
        self.contentView.placeholderIconView.image = self.bubbleViewStyle.placeholderIconImage(viewModel: self.messageViewModel)
        self.contentView.placeholderIconView.tintColor = self.bubbleViewStyle.placeholderIconTintColor(viewModel: self.messageViewModel)

        if let image = self.messageViewModel.image.value {
            self.contentView.imageView.image = image
            self.contentView.placeholderIconView.isHidden = true
        } else {
            self.contentView.imageView.image = self.bubbleViewStyle.placeholderBackgroundImage(viewModel: self.messageViewModel)
            self.contentView.placeholderIconView.isHidden = self.messageViewModel.transferStatus.value != .failed
        }

        if let overlayColor = self.bubbleViewStyle.overlayColor(viewModel: self.messageViewModel) {
            self.contentView.overlayView.backgroundColor = overlayColor
            self.contentView.overlayView.alpha = 1
            if self.contentView.overlayView.superview == nil {
                self.contentView.imageView.addSubview(self.contentView.overlayView)
            }
        } else {
            self.contentView.overlayView.alpha = 0
        }
        
    }

    // MARK: Layout
    
    open override func contentViewSizeThatFits(_ size: CGSize) -> CGSize {
        return self.calculatePhotoBubbleLayout(maximumWidth: size.width).size
    }
    
//    open override func sizeThatFits(_ size: CGSize) -> CGSize {
//        return self.calculatePhotoBubbleLayout(maximumWidth: size.width).size
//    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let layout = self.calculatePhotoBubbleLayout(maximumWidth: self.preferredMaxLayoutWidth)
        self.contentView.progressIndicatorView.center = layout.visualCenter
        self.contentView.placeholderIconView.center = layout.visualCenter
        self.contentView.placeholderIconView.bounds = CGRect(origin: .zero, size: layout.placeholderFrame.size)
        self.contentView.imageView.bma_rect = layout.photoFrame
        self.contentView.overlayView.bma_rect = self.contentView.imageView.bounds
        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
    }

    private func calculatePhotoBubbleLayout(maximumWidth: CGFloat) -> PhotoBubbleLayoutModel {
        let layoutContext = PhotoBubbleLayoutModel.LayoutContext(messageViewModel: self.messageViewModel, style: self.bubbleViewStyle, containerWidth: maximumWidth)
        let layoutModel = PhotoBubbleLayoutModel(layoutContext: layoutContext)
        layoutModel.calculateLayout()
        return layoutModel
    }
}

private class PhotoBubbleLayoutModel {
    var photoFrame: CGRect = .zero
    var placeholderFrame: CGRect = .zero
    var visualCenter: CGPoint = .zero // Because image is cropped a few points on the side of the tail, the apparent center will be a bit shifted
    var size: CGSize = .zero

    struct LayoutContext {
        let photoSize: CGSize
        let placeholderSize: CGSize
        let preferredMaxLayoutWidth: CGFloat
        let isIncoming: Bool
        let tailWidth: CGFloat

        init(photoSize: CGSize,
             placeholderSize: CGSize,
             tailWidth: CGFloat,
             isIncoming: Bool,
             preferredMaxLayoutWidth width: CGFloat) {
            self.photoSize = photoSize
            self.placeholderSize = placeholderSize
            self.tailWidth = tailWidth
            self.isIncoming = isIncoming
            self.preferredMaxLayoutWidth = width
        }

        init(messageViewModel model: PhotoMessageViewModelProtocol,
             style: PhotoBubbleViewStyleProtocol,
             containerWidth width: CGFloat) {
            self.init(photoSize: style.bubbleSize(viewModel: model),
                      placeholderSize: style.placeholderIconImage(viewModel: model).size,
                      tailWidth: style.tailWidth(viewModel: model),
                      isIncoming: model.isIncoming,
                      preferredMaxLayoutWidth: width)
        }
    }

    let layoutContext: LayoutContext
    init(layoutContext: LayoutContext) {
        self.layoutContext = layoutContext
    }

    func calculateLayout() {
        let photoSize = self.layoutContext.photoSize
        self.photoFrame = CGRect(origin: .zero, size: photoSize)
        self.placeholderFrame = CGRect(origin: .zero, size: self.layoutContext.placeholderSize)
        let offsetX: CGFloat = 0.5 * self.layoutContext.tailWidth * (self.layoutContext.isIncoming ? 1.0 : -1.0)
        self.visualCenter = self.photoFrame.bma_center.bma_offsetBy(dx: offsetX, dy: 0)
        self.size = photoSize
    }
}
