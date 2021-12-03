import AppKit
import Combine
import Core

final class Subbar: NSVisualEffectView {
    private var subs = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) { nil }
    init(selected: CurrentValueSubject<[Core.Picture], Never>,
         zoom: CurrentValueSubject<Window.Zoom, Never>,
         clear: PassthroughSubject<Void, Never>) {
        
        super.init(frame: .zero)
        state = .active
        material = .menu
        
        let transition = CATransition()
        transition.timingFunction = .init(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromBottom
        transition.duration = 0.25
        
        let name = Text(vibrancy: true)
        name.font = .preferredFont(forTextStyle: .body)
        name.textColor = .labelColor
        
        let date = Text(vibrancy: true)
        
        let resolution = Text(vibrancy: true)
        
        let speed = Text(vibrancy: true)
        
        let size = Text(vibrancy: true)
        
        let count = Text(vibrancy: true)
        count.font = .preferredFont(forTextStyle: .body)
        count.textColor = .labelColor
        
        let clearing = Plain(title: "Clear")
        clearing
            .click
            .subscribe(clear)
            .store(in: &subs)
        
        let single = NSStackView(views: [
            name,
            Separator(mode: .vertical),
            date,
            Separator(mode: .vertical),
            resolution,
            Separator(mode: .vertical),
            speed,
            Separator(mode: .vertical),
            size])
        single.translatesAutoresizingMaskIntoConstraints = false
        addSubview(single)
        
        let multiple = NSStackView(views: [count])
        multiple.translatesAutoresizingMaskIntoConstraints = false
        addSubview(multiple)
        
        let right = NSStackView(views: [clearing])
        right.translatesAutoresizingMaskIntoConstraints = false
        addSubview(right)
        
        selected
            .removeDuplicates()
            .combineLatest(zoom
                            .removeDuplicates())
            .sink { selected, zoom in
                switch selected.count {
                case 0:
                    single.isHidden = true
                    multiple.isHidden = true
                    clearing.state = .hidden
                    
                    name.stringValue = ""
                    date.attributedStringValue = .init()
                    resolution.attributedStringValue = .init()
                    speed.attributedStringValue = .init()
                    size.attributedStringValue = .init()
                    count.attributedStringValue = .init()
                case 1:
                    name.layer?.add(transition, forKey: "transition")
                    name.stringValue = selected.first!.id.lastPathComponent
                    
                    date.layer?.add(transition, forKey: "transition")
                    date.attributedStringValue = .make {
                        $0.append(.make("Date", attributes: [
                            .font: NSFont.preferredFont(forTextStyle: .caption1),
                            .foregroundColor: NSColor.tertiaryLabelColor]))
                        $0.newLine()
                        $0.append(.make(selected.first!.date.formatted(), attributes: [
                            .font: NSFont.preferredFont(forTextStyle: .callout),
                            .foregroundColor: NSColor.secondaryLabelColor]))
                    }
                    
                    resolution.layer?.add(transition, forKey: "transition")
                    resolution.attributedStringValue = .make {
                        $0.append(.make("Dimensions", attributes: [
                            .font: NSFont.preferredFont(forTextStyle: .caption1),
                            .foregroundColor: NSColor.tertiaryLabelColor]))
                        $0.newLine()
                        $0.append(.make("\(selected.first!.size.width)×\(selected.first!.size.height)", attributes: [
                            .font: NSFont.monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .callout).pointSize, weight: .regular),
                            .foregroundColor: NSColor.secondaryLabelColor]))
                    }
                    
                    speed.layer?.add(transition, forKey: "transition")
                    speed.attributedStringValue = .make { string in
                        string.append(.make("Speed", attributes: [
                            .font: NSFont.preferredFont(forTextStyle: .caption1),
                            .foregroundColor: NSColor.tertiaryLabelColor]))
                        string.newLine()
                        
                        switch selected.first!.speed {
                        case let .iso(iso):
                            string.append(.make(iso.formatted(), attributes: [
                                .font: NSFont.monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .callout).pointSize, weight: .regular),
                                .foregroundColor: NSColor.secondaryLabelColor]))
                        case .unknown:
                            string.append(.make("Unknown", attributes: [
                                .font: NSFont.preferredFont(forTextStyle: .callout),
                                .foregroundColor: NSColor.secondaryLabelColor]))
                        }
                    }
                    
                    size.layer?.add(transition, forKey: "transition")
                    size.attributedStringValue = .make {
                        $0.append(.make("Size", attributes: [
                            .font: NSFont.preferredFont(forTextStyle: .caption1),
                            .foregroundColor: NSColor.tertiaryLabelColor]))
                        $0.newLine()
                        $0.append(.make(selected.first!.bytes.formatted(.byteCount(style: .file)), attributes: [
                            .font: NSFont.monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .callout).pointSize, weight: .regular),
                            .foregroundColor: NSColor.secondaryLabelColor]))
                    }
                    
                    single.isHidden = false
                    multiple.isHidden = true
                    clearing.state = zoom == .grid ? .on : .hidden
                    
                    count.attributedStringValue = .init()
                default:
                    count.layer?.add(transition, forKey: "transition")
                    count.attributedStringValue = .make {
                        $0.append(.make(selected.count.formatted(), attributes: [
                            .font: NSFont.monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular),
                            .foregroundColor: NSColor.labelColor]))
                        $0.newLine()
                        $0.append(.make("selected", attributes: [
                            .font: NSFont.preferredFont(forTextStyle: .callout),
                            .foregroundColor: NSColor.secondaryLabelColor]))
                    }
                    
                    single.isHidden = true
                    multiple.isHidden = false
                    clearing.state = zoom == .grid ? .on : .hidden
                    
                    name.stringValue = ""
                    date.attributedStringValue = .init()
                    resolution.attributedStringValue = .init()
                    speed.attributedStringValue = .init()
                    size.attributedStringValue = .init()
                }
            }
            .store(in: &subs)
        
        single.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        single.rightAnchor.constraint(lessThanOrEqualTo: right.leftAnchor).isActive = true
        multiple.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        multiple.rightAnchor.constraint(lessThanOrEqualTo: right.leftAnchor).isActive = true
        right.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        single.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        multiple.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        let rightRight = right.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -15)
        rightRight.priority = .defaultLow
        rightRight.isActive = true
    }
}
