import AppKit
import Combine
import Core

extension Window {
    final class Detail: Collection<Detail.Cell, Info> {
        required init?(coder: NSCoder) { nil }
        init(info: CurrentValueSubject<[Info], Never>) {
            super.init(active: .activeInKeyWindow)
            
            let size = PassthroughSubject<CGSize, Never>()
            
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
                    $0.bounds.size
                }
                .removeDuplicates()
                .subscribe(size)
                .store(in: &subs)
            
            info
                .removeDuplicates()
                .combineLatest(size)
                .sink { [weak self] info, size in
                    
                    let result = info
                        .reduce(into: (items: Set<CollectionItem<Info>>(), x: CGFloat())) {
                                $0.items.insert(.init(
                                    info: $1,
                                    rect: .init(origin: .init(x: $0.x, y: 0), size: size)))
                                $0.x += size.width
                        }
                    self?.items.send(result.items)
                    self?.size.send(.init(width: result.x, height: size.height))
                }
                .store(in: &subs)
        }
    }
}
