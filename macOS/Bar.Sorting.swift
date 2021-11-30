import AppKit
import Combine

extension Bar {
    final class Sorting: NSPopover {
        private var subs = Set<AnyCancellable>()
        
        required init?(coder: NSCoder) { nil }
        init(sort: CurrentValueSubject<Window.Sort, Never>) {
            super.init()
            behavior = .semitransient
            contentSize = .init(width: 200, height: 200)
            contentViewController = .init()
            
            let view = NSView(frame: .init(origin: .zero, size: contentSize))
            contentViewController!.view = view
            
            let vibrant = Vibrant(layer: false)
            
            let title = Text(vibrancy: true)
            title.stringValue = "Order by"
            title.font = .preferredFont(forTextStyle: .title3)
            title.textColor = .labelColor
            vibrant.addSubview(title)
            
            let name = Option(title: "Name", image: "textformat.abc")
            name
                .click
                .sink { [weak self] in
                    sort.send(.name)
                    self?.close()
                }
                .store(in: &subs)
            
            let resolution = Option(title: "Resolution", image: "arrow.up.left.and.arrow.down.right")
            resolution
                .click
                .sink { [weak self] in
                    sort.send(.resolution)
                    self?.close()
                }
                .store(in: &subs)
            
            let size = Option(title: "File size", image: "memorychip")
            size
                .click
                .sink { [weak self] in
                    sort.send(.size)
                    self?.close()
                }
                .store(in: &subs)
            
            sort
                .first()
                .sink {
                    switch $0 {
                    case .name:
                        name.state = .selected
                        resolution.state = .on
                        size.state = .on
                    case .resolution:
                        name.state = .on
                        resolution.state = .selected
                        size.state = .on
                    case .size:
                        name.state = .on
                        resolution.state = .on
                        size.state = .selected
                    }
                }
                .store(in: &subs)
            
            let stack = NSStackView(views: [vibrant, name, resolution, size])
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.orientation = .vertical
            stack.alignment = .leading
            view.addSubview(stack)
            
            vibrant.rightAnchor.constraint(equalTo: title.rightAnchor).isActive = true
            
            title.topAnchor.constraint(equalTo: vibrant.topAnchor).isActive = true
            title.bottomAnchor.constraint(equalTo: vibrant.bottomAnchor, constant: -16).isActive = true
            title.leftAnchor.constraint(equalTo: vibrant.leftAnchor, constant: 12).isActive = true
            
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 30).isActive = true
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
            stack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
            stack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
        }
    }

}
