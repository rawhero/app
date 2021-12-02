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
            
            let empty = Text(vibrancy: true)
            empty.stringValue = "No photos found"
            empty.textColor = .secondaryLabelColor
            empty.font = .preferredFont(forTextStyle: .body)
            
            info
                .removeDuplicates()
                .sink { [weak self] in
                    self?.controller.arrangedObjects = $0.isEmpty ? [empty] : $0
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
            prepare
                .view
                .subviews
                .forEach {
                    $0.removeFromSuperview()
                }
            
            switch with {
            case let empty as Text:
                prepare.view.addSubview(empty)
                
                empty.centerYAnchor.constraint(equalTo: prepare.view.centerYAnchor).isActive = true
                empty.centerXAnchor.constraint(equalTo: prepare.view.centerXAnchor).isActive = true
            default:
                (prepare.view as! Cell).info = with as? Info
            }
        }
    }
}
