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

public typealias PhotoMessageCollectionViewCellDefaultStyle = PhotoBubbleViewDefaultStyle

open class PhotoBubbleViewDefaultStyle: BaseBubbleDefaultStyle, PhotoBubbleViewStyleProtocol {

    let sizes: Sizes
    let colors: Colors

    lazy private var placeholderBackgroundIncoming: UIImage = {
        return UIImage.bma_imageWithColor(self.baseStyle.baseColorIncoming, size: CGSize(width: 1, height: 1))
    }()
    
    lazy private var placeholderBackgroundOutgoing: UIImage = {
        return UIImage.bma_imageWithColor(self.baseStyle.baseColorOutgoing, size: CGSize(width: 1, height: 1))
    }()
    
    lazy private var placeholderIcon: UIImage = {
        return UIImage(named: "photo-bubble-placeholder-icon",
                       in: Bundle(for: PhotoBubbleViewDefaultStyle.self),
                       compatibleWith: nil)!
    }()
    
    public init(
        bubbleMasks: BaseBubbleDefaultStyle.BubbleMasks = BaseBubbleDefaultStyle.createDefaultBubbleMasks(),
        baseStyle: BaseMessageCollectionViewCellDefaultStyle = BaseMessageCollectionViewCellDefaultStyle(),
        incomingInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 19, bottom: 10, right: 15),
        outgoingInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 10),
        sizes: Sizes = PhotoBubbleViewDefaultStyle.createDefaultSizes(),
        colors: Colors = PhotoBubbleViewDefaultStyle.createDefaultColors()) {
            self.sizes = sizes
            self.colors = colors
        super.init(bubbleMasks: bubbleMasks, baseStyle: baseStyle, incomingInsets: incomingInsets, outgoingInsets: outgoingInsets)
    }

    open func placeholderBackgroundImage(viewModel: PhotoMessageViewModelProtocol) -> UIImage {
        return viewModel.isIncoming ? self.placeholderBackgroundIncoming : self.placeholderBackgroundOutgoing
    }

    open func placeholderIconImage(viewModel: PhotoMessageViewModelProtocol) -> UIImage {
        return self.placeholderIcon
    }

    open func placeholderIconTintColor(viewModel: PhotoMessageViewModelProtocol) -> UIColor {
        return viewModel.isIncoming ? self.colors.placeholderIconTintIncoming : self.colors.placeholderIconTintOutgoing
    }

    open func tailWidth(viewModel: PhotoMessageViewModelProtocol) -> CGFloat {
        return self.bubbleMasks.tailWidth
    }

    open func bubbleSize(viewModel: PhotoMessageViewModelProtocol) -> CGSize {
        let aspectRatio = viewModel.imageSize.height > 0 ? viewModel.imageSize.width / viewModel.imageSize.height : 0

        if aspectRatio == 0 || self.sizes.aspectRatioIntervalForSquaredSize.contains(aspectRatio) {
            return self.sizes.photoSizeSquare
        } else if aspectRatio < self.sizes.aspectRatioIntervalForSquaredSize.lowerBound {
            return self.sizes.photoSizePortrait
        } else {
            return self.sizes.photoSizeLandscape
        }
    }

    open func progressIndicatorColor(viewModel: PhotoMessageViewModelProtocol) -> UIColor {
        return viewModel.isIncoming ? self.colors.progressIndicatorColorIncoming : self.colors.progressIndicatorColorOutgoing
    }

    open func overlayColor(viewModel: PhotoMessageViewModelProtocol) -> UIColor? {
        let showsOverlay = viewModel.image.value != nil && (viewModel.transferStatus.value == .transfering || viewModel.status != MessageViewModelStatus.success)
        return showsOverlay ? self.colors.overlayColor : nil
    }

}

public extension PhotoBubbleViewDefaultStyle {
    
    public struct Sizes {
        public let aspectRatioIntervalForSquaredSize: ClosedRange<CGFloat>
        public let photoSizeLandscape: CGSize
        public let photoSizePortrait: CGSize
        public let photoSizeSquare: CGSize
        public init(
            aspectRatioIntervalForSquaredSize: ClosedRange<CGFloat>,
            photoSizeLandscape: CGSize,
            photoSizePortrait: CGSize,
            photoSizeSquare: CGSize) {
            self.aspectRatioIntervalForSquaredSize = aspectRatioIntervalForSquaredSize
            self.photoSizeLandscape = photoSizeLandscape
            self.photoSizePortrait = photoSizePortrait
            self.photoSizeSquare = photoSizeSquare
        }
    }
    
    public struct Colors {
        public let placeholderIconTintIncoming: UIColor
        public let placeholderIconTintOutgoing: UIColor
        public let progressIndicatorColorIncoming: UIColor
        public let progressIndicatorColorOutgoing: UIColor
        public let overlayColor: UIColor
        public init(
            placeholderIconTintIncoming: UIColor,
            placeholderIconTintOutgoing: UIColor,
            progressIndicatorColorIncoming: UIColor,
            progressIndicatorColorOutgoing: UIColor,
            overlayColor: UIColor) {
            self.placeholderIconTintIncoming = placeholderIconTintIncoming
            self.placeholderIconTintOutgoing = placeholderIconTintOutgoing
            self.progressIndicatorColorIncoming = progressIndicatorColorIncoming
            self.progressIndicatorColorOutgoing = progressIndicatorColorOutgoing
            self.overlayColor = overlayColor
        }
    }
    
}

// MARK: - Default values

public extension PhotoBubbleViewDefaultStyle {

    static public func createDefaultSizes() -> Sizes {
        return Sizes(
            aspectRatioIntervalForSquaredSize: 0.90...1.10,
            photoSizeLandscape: CGSize(width: 210, height: 136),
            photoSizePortrait: CGSize(width: 136, height: 210),
            photoSizeSquare: CGSize(width: 210, height: 210)
        )
    }

    static public func createDefaultColors() -> Colors {
        return Colors(
            placeholderIconTintIncoming: UIColor.bma_color(rgb: 0xced6dc),
            placeholderIconTintOutgoing: UIColor.bma_color(rgb: 0x508dfc),
            progressIndicatorColorIncoming: UIColor.bma_color(rgb: 0x98a3ab),
            progressIndicatorColorOutgoing: UIColor.white,
            overlayColor: UIColor.black.withAlphaComponent(0.70)
        )
    }
}
