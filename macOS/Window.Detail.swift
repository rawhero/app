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
            controller.view.autoresizingMask = [.width, .height]
            addSubview(controller.view)
            
            info
                .removeDuplicates()
                .sink { [weak self] in
                    self?.controller.arrangedObjects = $0.isEmpty ? [0] : $0
                }
                .store(in: &subs)
        }
        
        func pageController(_: NSPageController, identifierFor: Any) -> NSPageController.ObjectIdentifier {
            .init()
        }
        
        func pageController(_: NSPageController, viewControllerForIdentifier: NSPageController.ObjectIdentifier) -> NSViewController {
            let controller = NSViewController()
            controller.view = Cell()
            controller.view.autoresizingMask = [.width, .height]
            return controller
        }
        
        func pageController(_: NSPageController, prepare: NSViewController, with: Any?) {
            switch with {
            case let info as Info:
                (prepare.view as! Cell).info = info
            default:
                (prepare.view as! Cell).info = nil
            }
        }
    }
}
