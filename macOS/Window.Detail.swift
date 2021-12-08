import AppKit
import Combine
import Core

extension Window {
    final class Detail: NSView, NSPageControllerDelegate, NSMenuDelegate {
        let controller = NSPageController()
        private weak var selected: CurrentValueSubject<[Core.Picture], Never>!
        private weak var zoom: CurrentValueSubject<Zoom, Never>!
        private weak var trash: PassthroughSubject<[Core.Picture], Never>!
        private weak var share: PassthroughSubject<[Core.Picture], Never>!
        private var subs = Set<AnyCancellable>()
        
        required init?(coder: NSCoder) { nil }
        init(info: CurrentValueSubject<[Info], Never>,
             selected: CurrentValueSubject<[Core.Picture], Never>,
             zoom: CurrentValueSubject<Zoom, Never>,
             trash: PassthroughSubject<[Core.Picture], Never>,
             share: PassthroughSubject<[Core.Picture], Never>) {
            
            self.selected = selected
            self.zoom = zoom
            self.trash = trash
            self.share = share
            
            super.init(frame: .zero)
            menu = .init()
            menu!.delegate = self
            
            translatesAutoresizingMaskIntoConstraints = false
            controller.delegate = self
            controller.transitionStyle = .horizontalStrip
            controller.view = .init(frame: .zero)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(controller.view)
            
            controller.view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            controller.view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            controller.view.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            controller.view.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            
            if selected.value.isEmpty,
               let first = info.value.first {
                selected.send([first.picture])
            }
            
            info
                .removeDuplicates()
                .sink { [weak self] in
                    self?.controller.arrangedObjects = $0.isEmpty ? [""] : $0
                }
                .store(in: &subs)
            
            selected
                .compactMap {
                    $0
                        .first
                        .flatMap { first in
                            info
                                .value
                                .firstIndex { $0.picture.id == first.id }
                        }
                }
                .sink { [weak self] in
                    if $0 == self?.controller.selectedIndex {
                        self?.controller.animator().selectedIndex = $0
                    } else {
                        self?.controller.selectedIndex = $0
                    }
                }
                .store(in: &subs)
        }
        
        func pageController(_: NSPageController, identifierFor: Any) -> NSPageController.ObjectIdentifier {
            switch identifierFor {
            case let info as Info:
                return info.id
            default:
                return identifierFor as! String
            }
        }
        
        func pageController(_: NSPageController, viewControllerForIdentifier: NSPageController.ObjectIdentifier) -> NSViewController {
            let controller = NSViewController()
            controller.view = viewControllerForIdentifier.isEmpty ? NSView() : Cell()
            controller.view.autoresizingMask = [.width, .height]
            return controller
        }
        
        func pageController(_: NSPageController, prepare: NSViewController, with: Any?) {
            if let info = with as? Info {
                if info.picture.id == selected.value.first?.id {
                    (prepare.view as! Cell).animate = false
                }
                (prepare.view as! Cell).info = info
            }
        }
        
        func pageController(_: NSPageController, didTransitionTo: Any) {
            if let info = didTransitionTo as? Info {
                selected.send([info.picture])
            }
        }
        
        func menuNeedsUpdate(_ menu: NSMenu) {
            var items = [NSMenuItem]()
            
            if !selected.value.isEmpty {
                items += [
                    .child("Show in Finder", #selector(showInFinder)) {
                        $0.target = self
                    },
                    .separator(),
                    .child("Zoom out", #selector(zoomHighlighted)) {
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
        
        override var frame: NSRect {
            didSet {
                controller
                    .view
                    .subviews
                    .forEach {
                        $0
                            .subviews
                            .forEach {
                                $0.frame.size = frame.size
                            }
                    }
            }
        }
        
        override func mouseUp(with: NSEvent) {
            switch with.clickCount {
            case 2:
                zoom.send(.grid)
            default:
                super.mouseUp(with: with)
            }
        }
        
        @objc private func showInFinder() {
            guard let picture = selected.value.first else { return }
            NSWorkspace.shared.activateFileViewerSelecting([picture.id.absoluteURL])
        }
        
        @objc private func exportSelected() {
            guard let picture = selected.value.first else { return }
            share.send([picture])
        }
        
        @objc private func deleteSelected() {
            guard let picture = selected.value.first else { return }
            trash.send([picture])
        }
        
        @objc private func zoomHighlighted() {
            zoom.send(.grid)
        }
    }
}
