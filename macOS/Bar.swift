import AppKit
import Combine

final class Bar: NSVisualEffectView {
    private weak var zoom: CurrentValueSubject<Window.Zoom, Never>!
    private var subs = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) { nil }
    init(
        url: URL,
        count: CurrentValueSubject<Int, Never>,
        sort: CurrentValueSubject<Window.Sort, Never>,
        zoom: CurrentValueSubject<Window.Zoom, Never>) {
            self.zoom = zoom
            
            super.init(frame: .zero)
            state = .active
            material = .menu
            
            let title = Text(vibrancy: true)
            
            let sorting = Option(icon: "arrow.up.arrow.down", size: 13)
            sorting.toolTip = "Order images by"
            sorting
                .click
                .sink {
                    let pop = Sorting(sort: sort)
                    pop.show(relativeTo: sorting.bounds, of: sorting, preferredEdge: .maxY)
                    pop.contentViewController!.view.window!.makeKey()
                }
                .store(in: &subs)
            
            let zooming = NSSegmentedControl(images: ["square.grid.2x2", "rectangle"]
                                                .compactMap {
                                                    .init(systemSymbolName: $0, accessibilityDescription: nil)
                                                        .flatMap {
                                                            $0
                                                                .withSymbolConfiguration(.init(pointSize: 13, weight: .regular)
                                                                                        .applying(.init(hierarchicalColor: .secondaryLabelColor)))
                                                        }
                                                }, trackingMode: .selectOne, target: self, action: #selector(change))
            zooming.translatesAutoresizingMaskIntoConstraints = false
            zooming.segmentDistribution = .fit
            zooming.segmentStyle = .rounded
            zooming.selectedSegment = 0
            
            let left = NSStackView(views: [title, sorting, zooming])
            left.translatesAutoresizingMaskIntoConstraints = false
            left.spacing = 16
            addSubview(left)
            
            left.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
            left.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
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
    
    @objc private func change(_ segemented: NSSegmentedControl) {
        zoom.send(.init(rawValue: segemented.selectedSegment)!)
    }
}
