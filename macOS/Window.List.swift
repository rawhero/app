import AppKit
import Combine
import Core

extension Window {
    final class List: Collection<Cell, Info> {
        private static let insets2 = Cell.spacing + Cell.spacing
        private let click = PassthroughSubject<CGPoint, Never>()
        private let info = PassthroughSubject<[Info], Never>()
        private let thumbnails = Camera(strategy: .thumbnail)
        
        required init?(coder: NSCoder) { nil }
        init(pictures: PassthroughSubject<[Core.Picture], Never>,
             selected: CurrentValueSubject<[Core.Picture], Never>,
             clear: PassthroughSubject<Void, Never>) {
            
            super.init(active: .activeInKeyWindow)
            scrollerInsets.top = 5
            scrollerInsets.bottom = 5
            
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
                                let height = $1.height(for: columns.width)
                                
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
            
            click
                .compactMap { [weak self] point in
                    self?
                        .cells
                        .first {
                            $0
                                .item
                                .map {
                                    $0
                                        .rect
                                        .contains(point)
                                }
                            ?? false
                        }
                }
                .sink { [weak self] cell in
                    guard let info = cell.item?.info else { return }
                    
                    switch cell.state {
                    case .pressed:
                        cell.state = .none
                        selected.value.remove {
                            $0.id == info.picture.id
                        }
                        self?.selected.remove(info.id)
                    default:
                        cell.state = .pressed
                        selected.value.append(info.picture)
                        self?.selected.insert(info.id)
                    }
                }
                .store(in: &subs)
            
            pictures
                .sink { pictures in
                    Task { [weak self] in
                        await self?.received(pictures: pictures)
                    }
                }
                .store(in: &subs)
            
            clear
                .sink { [weak self] in
                    self?.clear.send()
                }
                .store(in: &subs)
        }
        
        override func mouseUp(with: NSEvent) {
            switch with.clickCount {
            case 2:
                break
            default:
                click.send(point(with: with))
            }
        }
        
        @MainActor private func received(pictures: [Core.Picture]) async {
            var items = [Info]()
            for picture in pictures {
                await items.append(.init(picture: picture, publisher: thumbnails.publisher(for: picture)))
            }
            info.send(items)
        }
    }
}
