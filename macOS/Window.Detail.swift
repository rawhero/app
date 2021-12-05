import AppKit
import Combine
import Core

extension Window {
    final class Detail: NSView, NSPageControllerDelegate {
        private weak var selected: CurrentValueSubject<[Core.Picture], Never>!
        private weak var zoom: CurrentValueSubject<Zoom, Never>!
        private var subs = Set<AnyCancellable>()
        private let controller = NSPageController()
        
        required init?(coder: NSCoder) { nil }
        init(info: CurrentValueSubject<[Info], Never>,
             selected: CurrentValueSubject<[Core.Picture], Never>,
             zoom: CurrentValueSubject<Zoom, Never>) {
            
            self.selected = selected
            self.zoom = zoom
            
            super.init(frame: .zero)
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
            
            info
                .removeDuplicates()
                .sink { [weak self] in
                    self?.controller.arrangedObjects = $0.isEmpty ? [""] : $0
                    
                    if let first = selected.value.first,
                       let index = $0.firstIndex(where: { $0.id == first.id.absoluteString }) {
                        self?.controller.selectedIndex = index
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
            controller.view = viewControllerForIdentifier.isEmpty ? Empty() : Cell()
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
    }
}
