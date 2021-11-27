import AppKit

final class Action: Control {
    override var frame: NSRect {
        didSet {
            gradient.frame = bounds
        }
    }
    
    private weak var gradient: Gradient!
    
    required init?(coder: NSCoder) { nil }
    init(title: String, color: NSColor) {
        let text = Text(vibrancy: false)
        text.stringValue = title
        text.font = .systemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        text.textColor = .white
    
        let gradient = Gradient()
        gradient.startPoint = .init(x: 0.5, y: 1)
        gradient.endPoint = .init(x: 0.5, y: 0)
        gradient.locations = [0, 1]
        gradient.colors = [CGColor.clear, CGColor(gray: 0, alpha: 0.3)]
        self.gradient = gradient
        
        super.init(layer: true)
        layer!.cornerRadius = 6
        layer!.backgroundColor = color.cgColor
        layer!.addSublayer(gradient)
        addSubview(text)
        
        heightAnchor.constraint(equalToConstant: 28).isActive = true
        rightAnchor.constraint(equalTo: text.rightAnchor, constant: 14).isActive = true
        
        text.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        text.leftAnchor.constraint(equalTo: leftAnchor, constant: 14).isActive = true
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        switch state {
        case .pressed:
            gradient.opacity = 0
        case .highlighted:
            gradient.opacity = 1
        default:
            gradient.opacity = 0.5
        }
    }
}
