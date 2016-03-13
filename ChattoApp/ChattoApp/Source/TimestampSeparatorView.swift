/*
The MIT License (MIT)

Copyright (c) 2016-present Zhao Wang.

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
import UIKit
import Chatto

extension NSDate {
    // Have a time stamp formatter to avoid keep creating new ones. This improves performance
    private static let weekdayAndDateStampDateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        dateFormatter.dateFormat = "EEEE, MMM dd yyyy" // "Monday, Mar 7 2016"
        return dateFormatter
    }()

    func toWeekDayAndDateString() -> String {
        return NSDate.weekdayAndDateStampDateFormatter.stringFromDate(self)
    }
}

class WeekDayDatestamp: ChatItemProtocol {
    let uid: String
    let type: String = WeekDayDatestamp.chatItemType

    static var chatItemType: ChatItemType {
        return "WeekDayDatestamp"
    }

    init(date: NSDate) {
        let datestampString = date.toWeekDayAndDateString()
        self.uid = datestampString.uppercaseString
    }
}

class WeekDayDatestampCollectionViewCell: UICollectionViewCell {
    private let label: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        label.font = UIFont.systemFontOfSize(12)
        label.textAlignment = .Center
        label.textColor = UIColor.grayColor()

        self.contentView.addSubview(label)
    }

    var text: String = "" {
        didSet {
            if oldValue != text {
                setTextOnLabel(text)
            }
        }
    }

    private func setTextOnLabel(text: String) {
        label.text = text
        label.sizeToFit()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.center = self.contentView.center
    }
}

public class WeekDayDatestampPresenterBuilder: ChatItemPresenterBuilderProtocol {

    public func canHandleChatItem(chatItem: ChatItemProtocol) -> Bool {
        return chatItem is WeekDayDatestamp
    }

    public func createPresenterWithChatItem(chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(self.canHandleChatItem(chatItem))
        return WeekDayDatestampPresenter(weekDayDatestamp: chatItem as! WeekDayDatestamp)
    }

    public var presenterType: ChatItemPresenterProtocol.Type {
        return WeekDayDatestampPresenter.self
    }
}

class WeekDayDatestampPresenter: ChatItemPresenterProtocol {

    let weekDayDatestamp: WeekDayDatestamp
    init (weekDayDatestamp: WeekDayDatestamp) {
        self.weekDayDatestamp = weekDayDatestamp
    }

    private static let cellReuseIdentifier = WeekDayDatestampCollectionViewCell.self.description()

    static func registerCells(collectionView: UICollectionView) {
        collectionView.registerClass(WeekDayDatestampCollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }

    func dequeueCell(collectionView collectionView: UICollectionView, indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(WeekDayDatestampPresenter.cellReuseIdentifier, forIndexPath: indexPath)
        return cell
    }

    func configureCell(cell: UICollectionViewCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        guard let datestamp = cell as? WeekDayDatestampCollectionViewCell else {
            assert(false, "expecting status cell")
            return
        }

        datestamp.text = weekDayDatestamp.uid
    }

    var canCalculateHeightInBackground: Bool {
        return true
    }

    func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 24
    }
}
