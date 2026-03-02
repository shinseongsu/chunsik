import SwiftUI
import AppKit
import Lottie

struct LottieViewRepresentable: NSViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .loop

    func makeNSView(context: Context) -> some NSView {
        let container = TransparentView()
        container.layer?.masksToBounds = false
        let av = LottieAnimationView(configuration: .init(renderingEngine: .mainThread))
        av.translatesAutoresizingMaskIntoConstraints = false
        av.wantsLayer = true
        av.layer?.masksToBounds = false
        av.contentMode = .scaleAspectFit
        av.loopMode = loopMode
        av.backgroundBehavior = .pauseAndRestore
        container.addSubview(av)
        NSLayoutConstraint.activate([
            av.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            av.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            av.topAnchor.constraint(equalTo: container.topAnchor),
            av.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        if let anim = LottieAnimation.named(animationName, bundle: .module) {
            av.animation = anim; av.play()
        }
        DispatchQueue.main.async { Self.clearLayers(container.layer) }
        context.coordinator.av = av
        context.coordinator.name = animationName
        return container
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        guard let av = context.coordinator.av, context.coordinator.name != animationName else { return }
        context.coordinator.name = animationName
        if let anim = LottieAnimation.named(animationName, bundle: .module) {
            av.animation = anim; av.loopMode = loopMode; av.play()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    private static func clearLayers(_ layer: CALayer?) {
        guard let layer else { return }
        layer.isOpaque = false; layer.backgroundColor = .clear
        layer.sublayers?.forEach { clearLayers($0) }
    }

    class Coordinator { var av: LottieAnimationView?; var name = "" }
}

class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in self?.clearBg(self) }
    }
    private func clearBg(_ view: NSView?) {
        guard let view else { return }
        view.wantsLayer = true; view.layer?.backgroundColor = .clear; view.layer?.isOpaque = false
        view.subviews.forEach { clearBg($0) }
    }
}

class TransparentView: NSView {
    override var isOpaque: Bool { false }
    override init(frame: NSRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    private func setup() { wantsLayer = true; layer?.backgroundColor = .clear; layer?.isOpaque = false }
    override func draw(_ dirtyRect: NSRect) { NSColor.clear.setFill(); dirtyRect.fill() }
}
