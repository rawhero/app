import AppKit
import Combine
import Core

extension Window {
    final class List: Collection<Cell, Info> {
        private static let insets = CGFloat(10)
        private static let insets2 = insets + insets
        private let select = PassthroughSubject<CGPoint, Never>()
        
        required init?(coder: NSCoder) { nil }
        init(pictures: PassthroughSubject<Set<Core.Picture>, Never>) {
            super.init(active: .activeInKeyWindow)
            scrollerInsets.top = 5
            scrollerInsets.bottom = 5
            
            let thumbnails = Camera(strategy: .thumbnail)
            let info = PassthroughSubject<[Info], Never>()
            let width = PassthroughSubject<CGFloat, Never>()
            
            NotificationCenter
                .default
                .publisher(for: NSView.frameDidChangeNotification)
                .compactMap {
                    $0.object as? NSClipView
                }
                .filter { [weak self] in
                    $0 == self?.contentView
                }
                .map {
                    $0.bounds.width
                }
                .removeDuplicates()
                .subscribe(width)
                .store(in: &subs)
            
            info
                .removeDuplicates()
                .combineLatest(width)
                .sink { [weak self] info, width in
                    let maxWidth = width - Self.insets2
                    let result = info
                        .reduce(into: (items: Set<CollectionItem<Info>>(), x: Self.insets, y: Self.insets)) {
                            if $0.x + $1.width > maxWidth {
                                $0.x = Self.insets
                                $0.y += Cell.height_spacing
                            }
                            
                            $0.items.insert(.init(
                                                info: $1,
                                                rect: .init(
                                                    x: $0.x,
                                                    y: $0.y,
                                                    width: $1.width,
                                                    height: Cell.height)))
                            
                            $0.x += Cell.spacing + $1.width
                        }
                    self?.items.send(result.items)
                    self?.size.send(.init(width: 0, height: result.y + Self.insets + Cell.height))
                }
                .store(in: &subs)
            
            select
                .map { [weak self] point in
                    self?
                        .cells
                        .compactMap(\.item)
                        .first {
                            $0
                                .rect
                                .contains(point)
                        }
                }
                .compactMap {
                    $0?.info.id
                }
                .sink { tag in
//                    change.send(tag)
                }
                .store(in: &subs)
            
            pictures
                .receive(on: DispatchQueue.main)
                .sink { pictures in
                    Task {
                        var items = [Info]()
                        for picture in pictures {
                            await items.append(.init(picture: picture, publisher: thumbnails.publisher(for: picture)))
                        }
                        info.send(items)
                    }
                }
                .store(in: &subs)
        }
        
        override func mouseUp(with: NSEvent) {
            switch with.clickCount {
            case 1:
                select.send(point(with: with))
            default:
                break
            }
        }
    }
}
