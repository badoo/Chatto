//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Chatto
import ChattoAdditions

final class AsyncAvatarLoadingViewController: DemoChatViewController {

    private var randomGenerator = SystemRandomNumberGenerator()

    override func viewDidLoad() {
        let messages: [ChatItemProtocol] = Array(0 ..< 10_000).map { index in
            let uid = String(index)
            let text = String(index)
            return DemoChatMessageFactory.makeTextMessage(uid, text: text, isIncoming: index % 2 == 0)
        }

        self.dataSource = DemoChatDataSource(messages: messages, pageSize: 50)
        super.viewDidLoad()
    }

    override func createTextMessageViewModelBuilder() -> DemoTextMessageViewModelBuilder {
        DemoTextMessageViewModelBuilder { message in
            let observable: Observable<UIImage?> = .init(nil)
            let imageSize = CGSize(width: 40, height: 40)
            let randomTime = Int(self.randomGenerator.next() % 10 + 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(randomTime)) {
                observable.value = UIImage.makeImage(ofSize: imageSize, text: message.uid)
            }
            return observable
        }
    }
}

private extension UIImage {
    static func makeImage(ofSize size: CGSize, text: String) -> UIImage {
        let frame = CGRect(origin: .zero, size: size)
        let label = UILabel(frame: frame)
        label.text = text
        label.backgroundColor = .white
        label.textColor = .black
        label.font = .systemFont(ofSize: 17)
        UIGraphicsBeginImageContext(size)
        let currentContext = UIGraphicsGetCurrentContext()!
        label.layer.render(in: currentContext)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
