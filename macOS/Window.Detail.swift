import AppKit
import Combine
import Core

extension Window {
    final class Detail: NSView, NSPageControllerDelegate {
        private var subs = Set<AnyCancellable>()
        private let controller = NSPageController()
        
        required init?(coder: NSCoder) { nil }
        init(info: CurrentValueSubject<[Info], Never>) {
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
                (prepare.view as! Cell).info = info
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
    }
}
