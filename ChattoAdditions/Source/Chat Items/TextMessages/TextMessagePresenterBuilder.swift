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

import Foundation
import Chatto

open class TextMessagePresenterBuilder<ViewModelBuilderT, InteractionHandlerT> :
    ChatItemPresenterBuilderProtocol where
    ViewModelBuilderT: ViewModelBuilderProtocol,
    ViewModelBuilderT.ViewModelT: TextMessageViewModelProtocol,
    InteractionHandlerT: BaseMessageInteractionHandlerProtocol,
    InteractionHandlerT.ViewModelT == ViewModelBuilderT.ViewModelT {
    
    public typealias ViewModelT = ViewModelBuilderT.ViewModelT
    public typealias ModelT = ViewModelBuilderT.ModelT

    public init(
        viewModelBuilder: ViewModelBuilderT,
        interactionHandler: InteractionHandlerT? = nil) {
            self.viewModelBuilder = viewModelBuilder
            self.interactionHandler = interactionHandler
    }

    let viewModelBuilder: ViewModelBuilderT
    let interactionHandler: InteractionHandlerT?
    let layoutCache = NSCache<AnyObject, AnyObject>()

    lazy var sizingCell: TextMessageCollectionViewCell<ViewModelT> = {
        var cell: TextMessageCollectionViewCell<ViewModelT>? = nil
        if Thread.isMainThread {
            cell = TextMessageCollectionViewCell<ViewModelT>.sizingCell()
        } else {
            DispatchQueue.main.sync(execute: {
                cell =  TextMessageCollectionViewCell<ViewModelT>.sizingCell()
            })
        }

        return cell!
    }()

    public lazy var textCellStyle: TextMessageCollectionViewCellStyleProtocol = TextMessageCollectionViewCellDefaultStyle()
    public lazy var baseCellStyle: BaseMessageCollectionViewCellStyleProtocol = BaseMessageCollectionViewCellDefaultStyle()

    open func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return self.viewModelBuilder.canCreateViewModel(fromModel: chatItem)
    }

    open func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        return TextMessagePresenter<ViewModelBuilderT, InteractionHandlerT>(
            messageModel: chatItem as! ModelT,
            viewModelBuilder: viewModelBuilder,
            interactionHandler: interactionHandler,
            sizingCell: sizingCell,
            baseCellStyle: baseCellStyle,
            textCellStyle: textCellStyle,
            layoutCache: layoutCache
        )
    }

    open var presenterType: ChatItemPresenterProtocol.Type {
        return TextMessagePresenter<ViewModelBuilderT, InteractionHandlerT>.self
    }
}
