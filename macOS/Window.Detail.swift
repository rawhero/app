import AppKit
import Combine
import Core

extension Window {
    final class Detail: NSView, NSPageControllerDelegate, NSMenuDelegate {
        var controller: NSPageController?
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
            
            if selected.value.isEmpty,
               let first = info.value.first {
                selected.send([first.picture])
            }
            
            info
                .sink { [weak self] in
                    guard let self = self else { return }
                    self.controller?.view.removeFromSuperview()
                    self.controller = .init()
                    self.controller!.arrangedObjects = $0.isEmpty ? [""] : $0
                    
                    self.controller!.delegate = self
                    self.controller!.transitionStyle = .horizontalStrip
                    self.controller!.view = .init(frame: .zero)
                    self.controller!.view.translatesAutoresizingMaskIntoConstraints = false
                    
                    self.addSubview(self.controller!.view)
                    
                    self.controller!.view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                    self.controller!.view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
                    self.controller!.view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
                    self.controller!.view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
                    
                    selected.send(selected.value)
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
                    self?.controller?.selectedIndex = $0
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
            controller.representedObject = viewControllerForIdentifier
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
            if let info = didTransitionTo as? Info,
               selected.value != [info.picture] {
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
                controller?
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
