import AppKit
import Combine

final class Bar: NSVisualEffectView {
    private var subs = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) { nil }
    init(url: URL) {
        super.init(frame: .zero)
        state = .active
        material = .menu
        
        let title = Text(vibrancy: true)
        title.stringValue = url.lastPathComponent
        title.font = .preferredFont(forTextStyle: .body)
        title.textColor = .secondaryLabelColor
        addSubview(title)
        
        title.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        title.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
    }
}
