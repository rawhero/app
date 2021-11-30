import AppKit
import Combine
import Core

extension Window {
    final class List: Collection<Cell, Info> {
        private static let insets2 = Cell.spacing + Cell.spacing
        private let select = PassthroughSubject<CGPoint, Never>()
        
        required init?(coder: NSCoder) { nil }
        init(pictures: PassthroughSubject<[Core.Picture], Never>) {
            super.init(active: .activeInKeyWindow)
            scrollerInsets.top = 5
            scrollerInsets.bottom = 5
            
            let thumbnails = Camera(strategy: .thumbnail)
            let info = PassthroughSubject<[Info], Never>()
            let columns = PassthroughSubject<(width: CGFloat, count: Int), Never>()
            
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
                    $0.bounds.width - Cell.spacing
                }
                .removeDuplicates()
                .map { width in
                    let count = max(Int(floor(width / Cell.width_spacing)), 1)
                    return (width: Cell.width + (width.truncatingRemainder(dividingBy: Cell.width_spacing) / .init(count)),
                            count: count)
                }
                .removeDuplicates { (before: (width: CGFloat, count: Int), current: (width: CGFloat, count: Int)) -> Bool in
                    before.width == current.width && before.count == current.count
                }
                .subscribe(columns)
                .store(in: &subs)
            
            info
                .removeDuplicates()
                .combineLatest(columns)
                .sink { [weak self] info, columns in
                    let result = info
                        .reduce(into: (
                            items: Set<CollectionItem<Info>>(),
                            y: Array(repeating: Cell.spacing, count: columns.count),
                            index: 0)) {
                                
                                let width_spacing = Cell.spacing + columns.width
                                let height = $1.size.width > 0 && $1.size.height > 0
                                ? columns.width / .init($1.size.width) * .init($1.size.height)
                                : columns.width
                                
                                $0.items.insert(.init(
                                    info: $1,
                                    rect: .init(
                                        x: (width_spacing * .init($0.index)) + Cell.spacing,
                                        y: $0.y[$0.index],
                                        width: columns.width,
                                        height: height)))
                                $0.y[$0.index] += height + Cell.spacing
                                
                                if $0.index < columns.count - 1 {
                                    $0.index += 1
                                } else {
                                    $0.index = 0
                                }
                        }
                    self?.items.send(result.items)
                    self?.size.send(.init(width: 0, height: result.y.max() ?? 0))
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
