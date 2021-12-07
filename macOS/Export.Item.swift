import AppKit
import Combine
import Core

extension Export {
    final class Item: NSView, NSTextFieldDelegate {
        private(set) var result: Data?
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
            
            let render = PassthroughSubject<Exporter, Never>()
            
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            layer = Layer()
            wantsLayer = true
            layer!.backgroundColor = NSColor.labelColor.withAlphaComponent(0.05).cgColor
            layer!.cornerRadius = 8
            
            let image = LayerImage()
            image.frame = .init(x: 3, y: 137, width: 80, height: 80)
            image.backgroundColor = NSColor.windowBackgroundColor.cgColor
            image.cornerRadius = 10
            layer!.addSublayer(image)
            
            let text = Text(vibrancy: true)
            text.stringValue = picture.id.lastPathComponent
            text.font = .systemFont(ofSize: NSFont.preferredFont(forTextStyle: .title3).pointSize, weight: .regular)
            text.textColor = .secondaryLabelColor
            text.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            text.maximumNumberOfLines = 1
            text.lineBreakMode = .byTruncatingTail
            addSubview(text)
            
            let mode = NSSegmentedControl(labels: ["jpg", "png"], trackingMode: .selectOne, target: self, action: #selector(change))
            mode.translatesAutoresizingMaskIntoConstraints = false
            mode.segmentStyle = .rounded
            addSubview(mode)
            
            let size = Text(vibrancy: true)
            size.font = .monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
            size.textColor = .secondaryLabelColor
            addSubview(size)
            
            let qualityTitle = Text(vibrancy: true)
            qualityTitle.stringValue = "Quality"
            qualityTitle.font = .preferredFont(forTextStyle: .footnote)
            qualityTitle.textColor = .secondaryLabelColor
            addSubview(qualityTitle)
            
            let quality = Text(vibrancy: true)
            quality.font = .monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
            quality.textColor = .secondaryLabelColor
            addSubview(quality)
            
            let sliderQuality = NSSlider(value: 1, minValue: 0.01, maxValue: 1, target: self, action: #selector(slideQuality))
            sliderQuality.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sliderQuality)
            
            let scaleTitle = Text(vibrancy: true)
            scaleTitle.stringValue = "Scale"
            scaleTitle.font = .preferredFont(forTextStyle: .footnote)
            scaleTitle.textColor = .secondaryLabelColor
            addSubview(scaleTitle)
            
            let scale = Field()
            scale.delegate = self
            self.scale = scale
            addSubview(scale)
            
            let sliderScale = NSSlider(value: 1, minValue: 0.01, maxValue: 1, target: self, action: #selector(slideScale))
            sliderScale.translatesAutoresizingMaskIntoConstraints = false
            addSubview(sliderScale)
            
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
            heightAnchor.constraint(equalToConstant: 220).isActive = true
            
            text.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
            text.leftAnchor.constraint(equalTo: leftAnchor, constant: 95).isActive = true
            text.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            mode.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 15).isActive = true
            mode.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            mode.widthAnchor.constraint(equalToConstant: 140).isActive = true
            
            size.rightAnchor.constraint(equalTo: mode.leftAnchor, constant: -10).isActive = true
            size.centerYAnchor.constraint(equalTo: mode.centerYAnchor).isActive = true
            
            qualityTitle.centerYAnchor.constraint(equalTo: quality.centerYAnchor).isActive = true
            qualityTitle.leftAnchor.constraint(equalTo: text.leftAnchor).isActive = true
            
            quality.topAnchor.constraint(equalTo: mode.bottomAnchor, constant: 20).isActive = true
            quality.leftAnchor.constraint(equalTo: sliderQuality.rightAnchor, constant: 10).isActive = true
            
            sliderQuality.centerYAnchor.constraint(equalTo: quality.centerYAnchor).isActive = true
            sliderQuality.leftAnchor.constraint(equalTo: sliderScale.leftAnchor).isActive = true
            sliderQuality.rightAnchor.constraint(equalTo: sliderScale.rightAnchor).isActive = true
            
            scaleTitle.centerYAnchor.constraint(equalTo: scale.centerYAnchor).isActive = true
            scaleTitle.leftAnchor.constraint(equalTo: text.leftAnchor).isActive = true
            
            scale.topAnchor.constraint(equalTo: quality.bottomAnchor, constant: 20).isActive = true
            scale.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            sliderScale.centerYAnchor.constraint(equalTo: scale.centerYAnchor).isActive = true
            sliderScale.leftAnchor.constraint(equalTo: scaleTitle.rightAnchor, constant: 15).isActive = true
            sliderScale.rightAnchor.constraint(equalTo: scale.leftAnchor, constant: -10).isActive = true
            
            widthTitle.centerYAnchor.constraint(equalTo: width.centerYAnchor).isActive = true
            widthTitle.leftAnchor.constraint(equalTo: text.leftAnchor).isActive = true
            
            width.topAnchor.constraint(equalTo: scale.bottomAnchor, constant: 10).isActive = true
            width.leftAnchor.constraint(equalTo: widthTitle.rightAnchor, constant: 10).isActive = true
            
            heightTitle.centerYAnchor.constraint(equalTo: width.centerYAnchor).isActive = true
            heightTitle.rightAnchor.constraint(equalTo: height.leftAnchor, constant: -10).isActive = true
            
            height.centerYAnchor.constraint(equalTo: width.centerYAnchor).isActive = true
            height.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
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
                .debounce(for: .milliseconds(750), scheduler: Camera.Pub.queues.randomElement()!)
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
                    sliderScale.doubleValue = exporter.scale
                    sliderQuality.doubleValue = exporter.quality
                    scale.stringValue = "\(exporter.scale)"
                    width.stringValue = "\(exporter.width)"
                    height.stringValue = "\(exporter.height)"
                    quality.stringValue = exporter.quality.formatted(.percent)
                    mode.selectedSegment = exporter.mode.rawValue
                    size.stringValue = "..."
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
        
        @objc private func change(_ segmented: NSSegmentedControl) {
            exporter.value.mode = .init(rawValue: segmented.selectedSegment)!
        }
        
        @objc private func slideQuality(_ slider: NSSlider) {
            exporter.value.quality(with: .init(Int(round(slider.doubleValue * 100))) / 100)
        }
        
        @objc private func slideScale(_ slider: NSSlider) {
            exporter.value.scale(with: .init(Int(round(slider.doubleValue * 100))) / 100)
        }
    }
}
