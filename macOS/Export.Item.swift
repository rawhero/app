import AppKit
import Combine
import Core

extension Export {
    final class Item: NSView, NSTextFieldDelegate {
        private(set) var result: Data?
        let url: URL
        
        private weak var scale: Field!
        private weak var width: Field!
        private weak var height: Field!
        private var subs = Set<AnyCancellable>()
        private let exporter: CurrentValueSubject<Exporter, Never>
        
        required init?(coder: NSCoder) { nil }
        init(picture: Core.Picture, thumbnails: Camera) {
            self.url = picture.id
            exporter = .init(.init(size: picture.size))
            
            let render = PassthroughSubject<Exporter, Never>()
            
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            layer = Layer()
            wantsLayer = true
            layer!.backgroundColor = NSColor.labelColor.withAlphaComponent(0.05).cgColor
            
            let image = LayerImage()
            image.frame = .init(x: 10, y: 10, width: 100, height: 100)
            image.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer!.addSublayer(image)
            
            let text = Text(vibrancy: true)
            text.stringValue = picture.id.lastPathComponent
            text.font = .preferredFont(forTextStyle: .body)
            text.textColor = .secondaryLabelColor
            text.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            addSubview(text)
            
            let size = Text(vibrancy: true)
            size.font = .monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
            size.textColor = .secondaryLabelColor
            addSubview(size)
            
            let scaleTitle = Text(vibrancy: true)
            scaleTitle.stringValue = "Scale"
            scaleTitle.font = .preferredFont(forTextStyle: .footnote)
            scaleTitle.textColor = .secondaryLabelColor
            addSubview(scaleTitle)
            
            let scale = Field()
            scale.delegate = self
            self.scale = scale
            addSubview(scale)
            
            let slider = NSSlider(value: 1, minValue: 0.01, maxValue: 1, target: self, action: #selector(slide))
            slider.translatesAutoresizingMaskIntoConstraints = false
            addSubview(slider)
            
            let widthTitle = Text(vibrancy: true)
            widthTitle.stringValue = "Width"
            widthTitle.font = .preferredFont(forTextStyle: .footnote)
            widthTitle.textColor = .secondaryLabelColor
            addSubview(widthTitle)
            
            let width = Field()
            width.delegate = self
            self.width = width
            addSubview(width)
            
            let heightTitle = Text(vibrancy: true)
            heightTitle.stringValue = "Height"
            heightTitle.font = .preferredFont(forTextStyle: .footnote)
            heightTitle.textColor = .secondaryLabelColor
            addSubview(heightTitle)
            
            let height = Field()
            height.delegate = self
            self.height = height
            addSubview(height)
            
            let transition = CATransition()
            transition.timingFunction = .init(name: .easeInEaseOut)
            transition.type = .push
            transition.subtype = .fromTop
            transition.duration = 0.25
            
            widthAnchor.constraint(equalToConstant: 460).isActive = true
            heightAnchor.constraint(equalToConstant: 120).isActive = true
            
            text.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
            text.leftAnchor.constraint(equalTo: leftAnchor, constant: 120).isActive = true
            text.rightAnchor.constraint(lessThanOrEqualTo: size.leftAnchor, constant: -10).isActive = true
            
            size.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
            size.centerYAnchor.constraint(equalTo: text.centerYAnchor).isActive = true
            
            scaleTitle.centerYAnchor.constraint(equalTo: scale.centerYAnchor).isActive = true
            scaleTitle.leftAnchor.constraint(equalTo: text.leftAnchor).isActive = true
            
            scale.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 10).isActive = true
            scale.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
            
            slider.centerYAnchor.constraint(equalTo: scale.centerYAnchor).isActive = true
            slider.leftAnchor.constraint(equalTo: scaleTitle.rightAnchor, constant: 10).isActive = true
            slider.rightAnchor.constraint(equalTo: scale.leftAnchor, constant: -10).isActive = true
            
            widthTitle.centerYAnchor.constraint(equalTo: width.centerYAnchor).isActive = true
            widthTitle.leftAnchor.constraint(equalTo: text.leftAnchor).isActive = true
            
            width.topAnchor.constraint(equalTo: scale.bottomAnchor, constant: 10).isActive = true
            width.leftAnchor.constraint(equalTo: widthTitle.rightAnchor, constant: 10).isActive = true
            
            heightTitle.centerYAnchor.constraint(equalTo: width.centerYAnchor).isActive = true
            heightTitle.rightAnchor.constraint(equalTo: height.leftAnchor, constant: -10).isActive = true
            
            height.centerYAnchor.constraint(equalTo: width.centerYAnchor).isActive = true
            height.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
            
            Task {
                await thumbnails
                    .publisher(for: picture)
                    .sink {
                        switch $0 {
                        case let .image(photo):
                            image.contents = photo
                        case .error:
                            image.contents = NSImage(
                                systemSymbolName: "exclamationmark.triangle.fill",
                                accessibilityDescription: nil)?
                                .withSymbolConfiguration(.init(pointSize: 20, weight: .light)
                                                            .applying(.init(hierarchicalColor: .systemPink)))
                            image.contentsGravity = .center
                        }
                    }
                    .store(in: &subs)
            }
            
            render
                .debounce(for: .milliseconds(450), scheduler: DispatchQueue.global(qos: .utility))
                .sink {
                    let result = CGImage.generate(url: picture.id, exporter: $0)
                    
                    DispatchQueue
                        .main
                        .async { [weak self] in
                            self?.result = result
                            size.stringValue = result?.count.formatted(.byteCount(style: .file)) ?? ""
                            size.layer?.add(transition, forKey: "transition")
                        }
                }
                .store(in: &subs)
            
            exporter
                .sink { exporter in
                    slider.doubleValue = exporter.scale
                    scale.stringValue = exporter.scale.formatted()
                    width.stringValue = exporter.width.formatted()
                    height.stringValue = exporter.height.formatted()
                    render.send(exporter)
                }
                .store(in: &subs)
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            switch obj.object as? Field {
            case scale:
                exporter.value.scale(with: scale.stringValue)
            case width:
                exporter.value.width(with: width.stringValue)
            case height:
                exporter.value.height(with: height.stringValue)
            default:
                break
            }
        }
        
        @objc private func slide(_ slider: NSSlider) {
            exporter.value.scale(with: .init(Int(slider.doubleValue * 100)) / 100)
        }
    }
}
