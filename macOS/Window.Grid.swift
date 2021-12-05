import AppKit
import Combine
import Core

extension Window {
    final class Grid: Collection<Grid.Cell, Info> {
        private static let insets2 = Cell.spacing + Cell.spacing
        private let click = PassthroughSubject<(point: CGPoint, multiple: Bool), Never>()
        private let double = PassthroughSubject<CGPoint, Never>()
        
        required init?(coder: NSCoder) { nil }
        init(info: CurrentValueSubject<[Info], Never>,
             selected: CurrentValueSubject<[Core.Picture], Never>,
             clear: PassthroughSubject<Void, Never>,
             zoom: CurrentValueSubject<Zoom, Never>,
             animateOut: PassthroughSubject<Void, Never>) {
            
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
                    self?.size.send(.init(width: 0, height: result.y.max() ?? 0))
                    
                    var animate: URL?
                    
                    if let selected = selected.value.first?.id,
                       let item = result.items.first(where: { $0.info.picture.id == selected}),
                       let midY = self?.bounds.midY,
                       self?.cells.isEmpty == true {
                        
                        self?.contentView.bounds.origin.y = max(item.rect.midY - midY, 0)
                        animate = selected
                    }
                    
                    self?.items.send(result.items)
                    
                    if let animate = animate,
                       let bounds = self?.bounds,
                       let offset = self?.contentView.bounds.origin.y {
                        self?
                            .cells
                            .first {
                                $0.item?.info.picture.id == animate
                            }
                            .map { cell in
                                cell.removeFromSuperlayer()
                                cell.backgroundColor = NSColor.controlBackgroundColor.cgColor
                                cell.frame = .init(x: 0, y: offset, width: bounds.width, height: bounds.height)
                                cell.gradient.isHidden = true
                                cell.margin.isHidden = true
                                cell.image.frame.size = cell.frame.size
                                self?.documentView?.layer?.addSublayer(cell)
                                
                                ["bounds", "position"]
                                    .forEach {
                                        let transition = CABasicAnimation(keyPath: $0)
                                        transition.fromValue = cell.frame.offsetBy(dx: cell.frame.width / 2, dy: cell.frame.height / 2)
                                        transition.duration = 0.35
                                        transition.timingFunction = .init(name: .easeOut)
                                        cell.add(transition, forKey: $0)
                                    }
                                
                                ["bounds", "position"]
                                    .forEach {
                                        let transition = CABasicAnimation(keyPath: $0)
                                        transition.fromValue = cell.frame.offsetBy(dx: cell.frame.width, dy: cell.frame.height)
                                        transition.duration = 0.35
                                        transition.timingFunction = .init(name: .easeOut)
                                        cell.image.add(transition, forKey: $0)
                                    }

                                cell.frame = cell.item!.rect
                                cell.image.frame.size = cell.frame.size

                                DispatchQueue
                                    .main
                                    .asyncAfter(deadline: .now() + .milliseconds(400)) {
                                        cell.gradient.isHidden = false
                                        cell.margin.isHidden = false
                                        cell.backgroundColor = NSColor.labelColor.withAlphaComponent(0.05).cgColor
                                    }
                            }
                    }
                }
                .store(in: &subs)
            
            click
                .compactMap { [weak self] click in
                    self?
                        .cells
                        .first {
                            $0
                                .item
                                .map {
                                    $0
                                        .rect
                                        .contains(click.point)
                                }
                            ?? false
                        }
                        .map {
                            (cell: $0, multiple: click.multiple)
                        }
                }
                .sink { [weak self] select in
                    guard let info = select.cell.item?.info else { return }
                    
                    switch select.cell.state {
                    case .pressed:
                        select.cell.state = .none
                        selected.value.remove {
                            $0.id == info.picture.id
                        }
                    default:
                        if !select.multiple {
                            self?
                                .cells
                                .filter {
                                    $0.state == .pressed
                                }
                                .forEach {
                                    $0.state = .none
                                }
                        }
                        
                        select.cell.state = .pressed
                        
                        if select.multiple {
                            selected.value.append(info.picture)
                        } else {
                            selected.value = [info.picture]
                        }
                    }
                }
                .store(in: &subs)
            
            double
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
                .sink {
                    guard let info = $0.item?.info else { return }
                    selected.value = [info.picture]
                    zoom.send(.detail)
                }
                .store(in: &subs)
            
            animateOut
                .sink { [weak self] in
                    guard
                        let bounds = self?.bounds,
                        let offset = self?.contentView.bounds.origin.y,
                        let id = selected.value.first?.id ?? info.value.first?.picture.id,
                        let cell = self?
                            .cells
                            .first(where: {
                                $0
                                    .item
                                    .map { $0.info.picture.id == id }
                                ?? false
                            })
                    else {
                        self?.animatedOut()
                        return
                    }
                    
                    cell.removeFromSuperlayer()
                    cell.backgroundColor = NSColor.controlBackgroundColor.cgColor
                    cell.gradient.isHidden = true
                    cell.margin.isHidden = true
                    self?.documentView?.layer?.addSublayer(cell)
                    
                    ["bounds", "position"]
                        .forEach {
                            let transition = CABasicAnimation(keyPath: $0)
                            transition.duration = 0.35
                            transition.timingFunction = .init(name: .easeIn)
                            cell.add(transition, forKey: $0)
                            cell.image.add(transition, forKey: $0)
                        }

                    cell.frame = .init(x: 0, y: offset, width: bounds.width, height: bounds.height)
                    cell.image.frame.size = cell.frame.size
                    
                    DispatchQueue
                        .main
                        .asyncAfter(deadline: .now() + .milliseconds(400)) {
                            self?.animatedOut()
                        }
                }
                .store(in: &subs)
            
            selected
                .sink { [weak self] in
                    self?.selected = .init($0.map(\.id.absoluteString))
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
                double.send(point(with: with))
            default:
                click.send((point: point(with: with), multiple: with.modifierFlags.contains(.shift)
                            || with.modifierFlags.contains(.command)))
            }
        }
        
        private func animatedOut() {
            (window as? Window)?.animatedOut()
            removeFromSuperview()
        }
    }
}
