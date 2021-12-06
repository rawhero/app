import AppKit
import Combine
import Core

extension Export {
    final class Item: NSView, NSTextFieldDelegate {
        let url: URL
        let exporter: CurrentValueSubject<Exporter, Never>
        private weak var scale: Field!
        private weak var width: Field!
        private weak var height: Field!
        private var subs = Set<AnyCancellable>()
        
        required init?(coder: NSCoder) { nil }
        init(picture: Core.Picture, thumbnails: Camera) {
            self.url = picture.id
            exporter = .init(.init(size: picture.size))
            
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
            addSubview(text)
            
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
            
            widthAnchor.constraint(equalToConstant: 460).isActive = true
            heightAnchor.constraint(equalToConstant: 120).isActive = true
            
            text.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
            text.leftAnchor.constraint(equalTo: leftAnchor, constant: 120).isActive = true
            
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
            
            exporter
                .sink {
                    slider.doubleValue = $0.scale
                    scale.stringValue = $0.scale.formatted()
                    width.stringValue = $0.width.formatted()
                    height.stringValue = $0.height.formatted()
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
