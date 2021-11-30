import AppKit
import Combine

final class Bar: NSVisualEffectView {
    private var subs = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) { nil }
    init(url: URL, count: CurrentValueSubject<Int, Never>, sort: CurrentValueSubject<Window.Sort, Never>) {
        super.init(frame: .zero)
        state = .active
        material = .menu
        
        let title = Text(vibrancy: true)
        addSubview(title)
        
        let sorting = Option(icon: "arrow.up.arrow.down", size: 14)
        sorting.toolTip = "Order images by"
        sorting
            .click
            .sink {
                let pop = Sorting(sort: sort)
                pop.show(relativeTo: sorting.bounds, of: sorting, preferredEdge: .maxY)
                pop.contentViewController!.view.window!.makeKey()
            }
            .store(in: &subs)
        
        let stack = NSStackView(views: [sorting])
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        title.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        title.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
        
        stack.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        stack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        count
            .receive(on: DispatchQueue.main)
            .sink { count in
                title.attributedStringValue = .make {
                    $0.append(.make(url.lastPathComponent, attributes: [
                        .font: NSFont.preferredFont(forTextStyle: .body),
                        .foregroundColor: NSColor.labelColor]))
                    
                    if count > 0 {
                        $0.newLine()
                        $0.append(.make(count.formatted(), attributes: [
                            .font: NSFont.monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .light),
                            .foregroundColor: NSColor.secondaryLabelColor]))
                        $0.append(.make(count == 1 ? " photo" : " photos", attributes: [
                            .font: NSFont.systemFont(ofSize: NSFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .light),
                            .foregroundColor: NSColor.secondaryLabelColor]))
                    }
                }
            }
            .store(in: &subs)
    }
}
