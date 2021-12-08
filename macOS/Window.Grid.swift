import AppKit
import Combine
import Core

extension Window {
    final class Grid: Collection<Grid.Cell, Info>, NSMenuDelegate {
        private(set) weak var move: PassthroughSubject<(date: Date, direction: Direction, multiple: Bool), Never>!
        private let click = PassthroughSubject<(point: CGPoint, multiple: Bool), Never>()
        private let double = PassthroughSubject<CGPoint, Never>()
        private let export = PassthroughSubject<[Info.ID], Never>()
        private let delete = PassthroughSubject<[Info.ID], Never>()
        private let zooming = PassthroughSubject<Info.ID, Never>()
        
        required init?(coder: NSCoder) { nil }
        init(info: CurrentValueSubject<[Info], Never>,
             selected: CurrentValueSubject<[Core.Picture], Never>,
             zoom: CurrentValueSubject<Zoom, Never>,
             animateOut: PassthroughSubject<Void, Never>,
             move: PassthroughSubject<(date: Date, direction: Direction, multiple: Bool), Never>,
             trash: PassthroughSubject<[Core.Picture], Never>,
             share: PassthroughSubject<[Core.Picture], Never>) {
            
            self.move = move
            
            super.init(active: .activeInKeyWindow)
            menu = .init()
            menu!.delegate = self
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
                    
                    if self?.cells.isEmpty == true,
                       let selected = selected.value.first?.id,
                       let item = result.items.first(where: { $0.info.picture.id == selected }) {
                        
                        self?.scrollTo(item: item, animate: false)
                        self?.items.send(result.items)
                        self?.animateIn(id: item.info.id)
                        
                    } else {
                        self?.items.send(result.items)
                    }
                }
                .store(in: &subs)
            
            click
                .map { [weak self] click in
                    self?
                        .cell(at: click.point)
                        .map {
                            (cell: $0, multiple: click.multiple)
                        }
                }
                .filter { $0 == nil }
                .sink { _ in
                    selected.send([])
                }
                .store(in: &subs)
            
            click
                .compactMap { [weak self] click in
                    self?
                        .cell(at: click.point)
                        .map {
                            (cell: $0, multiple: click.multiple)
                        }
                }
                .sink { select in
                    guard let info = select.cell.item?.info else { return }
                    
                    switch select.cell.state {
                    case .pressed:
                        selected.value.remove {
                            $0.id == info.picture.id
                        }
                    default:
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
                    self?.cell(at: point)?.item
                }
                .sink {
                    selected.value = [$0.info.picture]
                    zoom.send(.detail)
                }
                .store(in: &subs)
            
            animateOut
                .sink { [weak self] in
                    guard let picture = selected.value.first ?? info.value.first?.picture else { return }
                    self?.animateOut(picture: picture)
                }
                .store(in: &subs)
            
            selected
                .sink { [weak self] selected in
                    self?.selected = .init(selected.map(\.id.absoluteString))
                }
                .store(in: &subs)
            
            items
                .combineLatest(move)
                .removeDuplicates {
                    $0.1.date == $1.1.date
                }
                .filter { items, move in
                    !items.isEmpty
                }
                .sink { [weak self] items, move in
                    if let current = selected.value.last {
                        items
                            .item(from: current, with: move.direction)
                            .map { choosen in
                                if move.multiple {
                                    if let index = selected.value.firstIndex(of: choosen.info.picture) {
                                        selected.value.remove(at: index)
                                    }
                                    selected.value.append(choosen.info.picture)
                                } else {
                                    selected.send([choosen.info.picture])
                                }
                                
                                self?.scrollTo(item: choosen, animate: true)
                            }
                    } else {
                        selected.send([info.value.first!.picture])
                        self?.scrollTo(item: items.first { $0.info.id == info.value.first!.id }!, animate: true)
                    }
                }
                .store(in: &subs)
            
            export
                .sink {
                    share.send(
                        $0
                            .compactMap { id in
                                info
                                    .value
                                    .first {
                                        $0.id == id
                                    }?
                                    .picture
                            })
                }
                .store(in: &subs)
            
            zooming
                .sink { id in
                    guard let picture = info.value.first(where: { $0.id == id })?.picture else { return }
                    selected.send([picture])
                    zoom.send(.detail)
                }
                .store(in: &subs)
            
            delete
                .sink {
                    trash.send(
                        $0
                            .compactMap { id in
                                info
                                    .value
                                    .first {
                                        $0.id == id
                                    }?
                                    .picture
                            })
                }
                .store(in: &subs)
        }
        
        override func mouseUp(with: NSEvent) {
            switch with.clickCount {
            case 1:
                click.send((point: point(with: with), multiple: with.multiple))
            case 2:
                double.send(point(with: with))
            default:
                super.mouseUp(with: with)
            }
        }
        
        func menuNeedsUpdate(_ menu: NSMenu) {
            var items = [NSMenuItem]()
            
            if highlighted != nil {
                items += [
                    .child("Show in Finder", #selector(showInFinder)) {
                        $0.target = self
                    },
                    .separator(),
                    .child("Zoom in", #selector(zoomHighlighted)) {
                        $0.target = self
                    },
                    .separator(),
                    .child("Export", #selector(exportSelected)) {
                        $0.target = self
                    },
                    .separator(),
                    .child("Delete", #selector(deleteSelected)) {
                        $0.target = self
                    },
                    .separator()]
            }
            
            menu.items = items
        }
        
        private func scrollTo(item: CollectionItem<Info>, animate: Bool) {
            let y = max(item.rect.midY - bounds.midY, 0)
            if animate {
                contentView.animator().bounds.origin.y = y
            } else {
                contentView.bounds.origin.y = y
            }
        }
        
        private func animateIn(id: String) {
            cells
                .first {
                    $0.item?.info.id == id
                }
                .map { cell in
                    cell.removeFromSuperlayer()
                    cell.startAnimation()
                    cell.frame = .init(x: 0, y: contentView.bounds.origin.y, width: bounds.width, height: bounds.height)
                    cell.image.frame.size = cell.frame.size
                    documentView!.layer!.addSublayer(cell)
                    
                    ["bounds", "position"]
                        .forEach {
                            let transition = CABasicAnimation(keyPath: $0)
                            transition.fromValue = cell.frame.offsetBy(dx: cell.frame.width / 2, dy: cell.frame.height / 2)
                            transition.duration = 0.3
                            transition.timingFunction = .init(name: .easeIn)
                            cell.add(transition, forKey: $0)
                        }
                    
                    ["bounds", "position"]
                        .forEach {
                            let transition = CABasicAnimation(keyPath: $0)
                            transition.fromValue = cell.frame.offsetBy(dx: cell.frame.width, dy: cell.frame.height)
                            transition.duration = 0.3
                            transition.timingFunction = .init(name: .easeIn)
                            cell.image.add(transition, forKey: $0)
                        }
                    
                    cell.frame = cell.item!.rect
                    cell.image.frame.size = cell.frame.size
                    
                    DispatchQueue
                        .main
                        .asyncAfter(deadline: .now() + .milliseconds(400)) {
                            cell.endAnimation()
                        }
                }
        }
        
        private func animateOut(picture: Core.Picture) {
            guard
                let cell = cells
                    .first(where: {
                        $0
                            .item
                            .map { $0.info.picture.id == picture.id }
                        ?? false
                    })
            else {
                animatedOut()
                return
            }
            
            cell.removeFromSuperlayer()
            cell.startAnimation()
            documentView!.layer!.addSublayer(cell)
            
            ["bounds", "position"]
                .forEach {
                    let transition = CABasicAnimation(keyPath: $0)
                    transition.duration = 0.3
                    transition.timingFunction = .init(name: .easeOut)
                    cell.add(transition, forKey: $0)
                    cell.image.add(transition, forKey: $0)
                }
            
            cell.frame = .init(x: 0, y: contentView.bounds.origin.y, width: bounds.width, height: bounds.height)
            cell.image.frame.size = cell.frame.size
            
            DispatchQueue
                .main
                .asyncAfter(deadline: .now() + .milliseconds(400)) { [weak self] in
                    self?.animatedOut()
                }
        }
        
        private func animatedOut() {
            (window as? Window)?.animatedOut()
            removeFromSuperview()
        }
        
        @objc private func showInFinder() {
            guard let highlighted = highlighted else { return }
            NSWorkspace.shared.activateFileViewerSelecting((selected + [highlighted])
                                                            .compactMap(URL.init(string:))
                                                            .map(\.absoluteURL))
        }
        
        @objc private func exportSelected() {
            guard let highlighted = highlighted else { return }
            export.send(selected + [highlighted])
        }
        
        @objc private func deleteSelected() {
            guard let highlighted = highlighted else { return }
            delete.send(selected + [highlighted])
        }
        
        @objc private func zoomHighlighted() {
            guard let highlighted = highlighted else { return }
            zooming.send(highlighted)
        }
    }
}

private extension Set where Element == CollectionItem<Window.Info> {
    func item(from: Core.Picture, with: Window.Direction) -> Element? {
        let rect: CGRect
        let current = first { $0.info.picture.id == from.id }!.rect
        
        switch with {
        case .up:
            rect = .init(x: current.midX, y: current.minY - (Window.Grid.Cell.spacing + 2),
                         width: 2, height: 2)
        case .down:
            rect = .init(x: current.midX, y: current.maxY + Window.Grid.Cell.spacing + 2,
                         width: 2, height: 2)
        case .left:
            rect = .init(x: current.minX - (Window.Grid.Cell.spacing + 2), y: current.minY,
                         width: 2, height: Window.Grid.Cell.spacing + 2)
        case .right:
            rect = .init(x: current.maxX + Window.Grid.Cell.spacing + 2, y: current.minY,
                         width: 2, height: Window.Grid.Cell.spacing + 2)
        }
        
        return filter {
            $0
                .rect
                .intersects(rect)
        }
        .sorted {
            $0.rect.minY < $1.rect.minY
        }
        .first
    }
}
