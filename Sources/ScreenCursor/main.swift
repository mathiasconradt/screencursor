import Cocoa

extension Notification.Name {
    static let screenCursorSettingsChanged = Notification.Name("ScreenCursor.settingsChanged")
}

final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let enabled = "enabled"
        static let radius = "radius"
        static let borderWidth = "borderWidth"
        static let innerOpacity = "innerOpacity"
        static let clickFeedback = "clickFeedback"
        static let red = "colorRed"
        static let green = "colorGreen"
        static let blue = "colorBlue"
        static let alpha = "colorAlpha"
    }

    var enabled: Bool {
        get {
            if defaults.object(forKey: Key.enabled) == nil {
                return true
            }
            return defaults.bool(forKey: Key.enabled)
        }
        set {
            defaults.set(newValue, forKey: Key.enabled)
            postChange()
        }
    }

    var radius: CGFloat {
        get {
            let stored = defaults.double(forKey: Key.radius)
            return stored > 0 ? CGFloat(stored) : 52
        }
        set {
            defaults.set(Double(min(max(newValue, 12), 220)), forKey: Key.radius)
            postChange()
        }
    }

    var borderWidth: CGFloat {
        get {
            let stored = defaults.double(forKey: Key.borderWidth)
            return stored > 0 ? CGFloat(stored) : 4
        }
        set {
            defaults.set(Double(min(max(newValue, 1), 36)), forKey: Key.borderWidth)
            postChange()
        }
    }

    var innerOpacity: CGFloat {
        get {
            if defaults.object(forKey: Key.innerOpacity) == nil {
                return 0.18
            }
            return CGFloat(defaults.double(forKey: Key.innerOpacity))
        }
        set {
            defaults.set(Double(min(max(newValue, 0), 1)), forKey: Key.innerOpacity)
            postChange()
        }
    }

    var clickFeedback: Bool {
        get {
            if defaults.object(forKey: Key.clickFeedback) == nil {
                return true
            }
            return defaults.bool(forKey: Key.clickFeedback)
        }
        set {
            defaults.set(newValue, forKey: Key.clickFeedback)
            postChange()
        }
    }

    var color: NSColor {
        get {
            if defaults.object(forKey: Key.red) == nil {
                return NSColor.systemYellow.withAlphaComponent(0.85)
            }
            return NSColor(
                calibratedRed: CGFloat(defaults.double(forKey: Key.red)),
                green: CGFloat(defaults.double(forKey: Key.green)),
                blue: CGFloat(defaults.double(forKey: Key.blue)),
                alpha: CGFloat(defaults.double(forKey: Key.alpha))
            )
        }
        set {
            let color = newValue.usingColorSpace(.sRGB) ?? newValue
            defaults.set(Double(color.redComponent), forKey: Key.red)
            defaults.set(Double(color.greenComponent), forKey: Key.green)
            defaults.set(Double(color.blueComponent), forKey: Key.blue)
            defaults.set(Double(color.alphaComponent), forKey: Key.alpha)
            postChange()
        }
    }

    private func postChange() {
        NotificationCenter.default.post(name: .screenCursorSettingsChanged, object: self)
    }
}

final class HighlightView: NSView {
    var radius: CGFloat = SettingsStore.shared.radius {
        didSet { needsDisplay = true }
    }

    var color: NSColor = SettingsStore.shared.color {
        didSet { needsDisplay = true }
    }

    var borderWidth: CGFloat = SettingsStore.shared.borderWidth {
        didSet { needsDisplay = true }
    }

    var innerOpacity: CGFloat = SettingsStore.shared.innerOpacity {
        didSet { needsDisplay = true }
    }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let strokeWidth = borderWidth
        let circleRect = bounds.insetBy(dx: strokeWidth / 2 + 2, dy: strokeWidth / 2 + 2)
        let path = NSBezierPath(ovalIn: circleRect)

        color.withAlphaComponent(color.alphaComponent * innerOpacity).setFill()
        path.fill()

        color.withAlphaComponent(max(0.35, color.alphaComponent)).setStroke()
        path.lineWidth = strokeWidth
        path.stroke()
    }
}

final class OverlayController {
    private let window: NSWindow
    private let highlightView = HighlightView(frame: .zero)
    private var timer: Timer?
    private var lastWindowFrame = NSRect.zero
    private var clickMonitor: Any?
    private var animationStart: Date?

    init() {
        let diameter = (SettingsStore.shared.radius * 2) + 18
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: diameter, height: diameter),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.level = .screenSaver
        window.contentView = highlightView

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: .screenCursorSettingsChanged,
            object: nil
        )
    }

    func start() {
        settingsChanged()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 90.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            self?.animateClickFeedback()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        window.orderOut(nil)
    }

    @objc private func settingsChanged() {
        highlightView.radius = SettingsStore.shared.radius
        highlightView.color = SettingsStore.shared.color
        highlightView.borderWidth = SettingsStore.shared.borderWidth
        highlightView.innerOpacity = SettingsStore.shared.innerOpacity
        if SettingsStore.shared.enabled {
            window.orderFrontRegardless()
        } else {
            window.orderOut(nil)
        }
        tick()
    }

    private func tick() {
        guard SettingsStore.shared.enabled else { return }

        let radius = currentRadius()
        let diameter = (radius * 2) + 18
        let mouse = NSEvent.mouseLocation
        let frame = NSRect(
            x: mouse.x - diameter / 2,
            y: mouse.y - diameter / 2,
            width: diameter,
            height: diameter
        )

        if !frame.equalTo(lastWindowFrame) {
            window.setFrame(frame, display: true)
            lastWindowFrame = frame
        }
    }

    private func animateClickFeedback() {
        guard SettingsStore.shared.enabled, SettingsStore.shared.clickFeedback else { return }
        animationStart = Date()
    }

    private func currentRadius() -> CGFloat {
        let baseRadius = SettingsStore.shared.radius
        guard SettingsStore.shared.clickFeedback, let animationStart else {
            highlightView.radius = baseRadius
            return baseRadius
        }

        let elapsed = Date().timeIntervalSince(animationStart)
        let duration = 0.18

        if elapsed >= duration {
            self.animationStart = nil
            highlightView.radius = baseRadius
            return baseRadius
        }

        let progress = elapsed / duration
        let scale: CGFloat
        if progress < 0.35 {
            scale = 1.0 - (CGFloat(progress / 0.35) * 0.13)
        } else {
            scale = 0.87 + (CGFloat((progress - 0.35) / 0.65) * 0.13)
        }

        let animatedRadius = baseRadius * scale
        highlightView.radius = animatedRadius
        return animatedRadius
    }
}

final class SettingsWindowController: NSWindowController {
    private let radiusSlider = NSSlider(value: Double(SettingsStore.shared.radius), minValue: 12, maxValue: 220, target: nil, action: nil)
    private let radiusValueLabel = NSTextField(labelWithString: "")
    private let borderWidthSlider = NSSlider(value: Double(SettingsStore.shared.borderWidth), minValue: 1, maxValue: 36, target: nil, action: nil)
    private let borderWidthValueLabel = NSTextField(labelWithString: "")
    private let innerOpacitySlider = NSSlider(value: Double(SettingsStore.shared.innerOpacity), minValue: 0, maxValue: 1, target: nil, action: nil)
    private let innerOpacityValueLabel = NSTextField(labelWithString: "")
    private let colorWell = NSColorWell(frame: .zero)
    private let enabledCheckbox = NSButton(checkboxWithTitle: "Enable highlight", target: nil, action: nil)
    private let clickFeedbackCheckbox = NSButton(checkboxWithTitle: "Click feedback", target: nil, action: nil)

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 348),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screen Cursor Settings"
        window.center()
        super.init(window: window)
        buildContent()
        syncFromSettings()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncFromSettings),
            name: .screenCursorSettingsChanged,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildContent() {
        guard let window else { return }

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let title = NSTextField(labelWithString: "Screen Cursor")
        title.font = .systemFont(ofSize: 20, weight: .semibold)

        enabledCheckbox.target = self
        enabledCheckbox.action = #selector(enabledChanged)

        clickFeedbackCheckbox.target = self
        clickFeedbackCheckbox.action = #selector(clickFeedbackChanged)

        let radiusLabel = NSTextField(labelWithString: "Radius")
        radiusLabel.font = .systemFont(ofSize: 13, weight: .medium)

        radiusSlider.target = self
        radiusSlider.action = #selector(radiusChanged)
        radiusSlider.isContinuous = true

        radiusValueLabel.alignment = .right
        radiusValueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        let borderWidthLabel = NSTextField(labelWithString: "Border width")
        borderWidthLabel.font = .systemFont(ofSize: 13, weight: .medium)

        borderWidthSlider.target = self
        borderWidthSlider.action = #selector(borderWidthChanged)
        borderWidthSlider.isContinuous = true

        borderWidthValueLabel.alignment = .right
        borderWidthValueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        let innerOpacityLabel = NSTextField(labelWithString: "Inner opacity")
        innerOpacityLabel.font = .systemFont(ofSize: 13, weight: .medium)

        innerOpacitySlider.target = self
        innerOpacitySlider.action = #selector(innerOpacityChanged)
        innerOpacitySlider.isContinuous = true

        innerOpacityValueLabel.alignment = .right
        innerOpacityValueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        let colorLabel = NSTextField(labelWithString: "Color")
        colorLabel.font = .systemFont(ofSize: 13, weight: .medium)

        NSColorPanel.shared.showsAlpha = true
        colorWell.target = self
        colorWell.action = #selector(colorChanged)

        [
            title,
            enabledCheckbox,
            radiusLabel,
            radiusSlider,
            radiusValueLabel,
            borderWidthLabel,
            borderWidthSlider,
            borderWidthValueLabel,
            innerOpacityLabel,
            innerOpacitySlider,
            innerOpacityValueLabel,
            colorLabel,
            colorWell,
            clickFeedbackCheckbox
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            enabledCheckbox.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 18),
            enabledCheckbox.leadingAnchor.constraint(equalTo: title.leadingAnchor),

            radiusLabel.topAnchor.constraint(equalTo: enabledCheckbox.bottomAnchor, constant: 22),
            radiusLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            radiusLabel.widthAnchor.constraint(equalToConstant: 76),

            radiusSlider.centerYAnchor.constraint(equalTo: radiusLabel.centerYAnchor),
            radiusSlider.leadingAnchor.constraint(equalTo: radiusLabel.trailingAnchor, constant: 16),
            radiusSlider.trailingAnchor.constraint(equalTo: radiusValueLabel.leadingAnchor, constant: -12),

            radiusValueLabel.centerYAnchor.constraint(equalTo: radiusLabel.centerYAnchor),
            radiusValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            radiusValueLabel.widthAnchor.constraint(equalToConstant: 64),

            borderWidthLabel.topAnchor.constraint(equalTo: radiusLabel.bottomAnchor, constant: 24),
            borderWidthLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            borderWidthLabel.widthAnchor.constraint(equalToConstant: 96),

            borderWidthSlider.centerYAnchor.constraint(equalTo: borderWidthLabel.centerYAnchor),
            borderWidthSlider.leadingAnchor.constraint(equalTo: borderWidthLabel.trailingAnchor, constant: 16),
            borderWidthSlider.trailingAnchor.constraint(equalTo: borderWidthValueLabel.leadingAnchor, constant: -12),

            borderWidthValueLabel.centerYAnchor.constraint(equalTo: borderWidthLabel.centerYAnchor),
            borderWidthValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            borderWidthValueLabel.widthAnchor.constraint(equalToConstant: 64),

            innerOpacityLabel.topAnchor.constraint(equalTo: borderWidthLabel.bottomAnchor, constant: 24),
            innerOpacityLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            innerOpacityLabel.widthAnchor.constraint(equalTo: borderWidthLabel.widthAnchor),

            innerOpacitySlider.centerYAnchor.constraint(equalTo: innerOpacityLabel.centerYAnchor),
            innerOpacitySlider.leadingAnchor.constraint(equalTo: borderWidthSlider.leadingAnchor),
            innerOpacitySlider.trailingAnchor.constraint(equalTo: innerOpacityValueLabel.leadingAnchor, constant: -12),

            innerOpacityValueLabel.centerYAnchor.constraint(equalTo: innerOpacityLabel.centerYAnchor),
            innerOpacityValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            innerOpacityValueLabel.widthAnchor.constraint(equalToConstant: 64),

            colorLabel.topAnchor.constraint(equalTo: innerOpacityLabel.bottomAnchor, constant: 28),
            colorLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            colorLabel.widthAnchor.constraint(equalTo: borderWidthLabel.widthAnchor),

            colorWell.centerYAnchor.constraint(equalTo: colorLabel.centerYAnchor),
            colorWell.leadingAnchor.constraint(equalTo: borderWidthSlider.leadingAnchor),
            colorWell.widthAnchor.constraint(equalToConstant: 74),
            colorWell.heightAnchor.constraint(equalToConstant: 32),

            clickFeedbackCheckbox.topAnchor.constraint(equalTo: colorWell.bottomAnchor, constant: 22),
            clickFeedbackCheckbox.leadingAnchor.constraint(equalTo: title.leadingAnchor)
        ])
    }

    @objc private func syncFromSettings() {
        enabledCheckbox.state = SettingsStore.shared.enabled ? .on : .off
        clickFeedbackCheckbox.state = SettingsStore.shared.clickFeedback ? .on : .off
        radiusSlider.doubleValue = Double(SettingsStore.shared.radius)
        radiusValueLabel.stringValue = "\(Int(SettingsStore.shared.radius.rounded())) px"
        borderWidthSlider.doubleValue = Double(SettingsStore.shared.borderWidth)
        borderWidthValueLabel.stringValue = "\(Int(SettingsStore.shared.borderWidth.rounded())) px"
        innerOpacitySlider.doubleValue = Double(SettingsStore.shared.innerOpacity)
        innerOpacityValueLabel.stringValue = "\(Int((SettingsStore.shared.innerOpacity * 100).rounded()))%"
        colorWell.color = SettingsStore.shared.color
    }

    @objc private func enabledChanged() {
        SettingsStore.shared.enabled = enabledCheckbox.state == .on
    }

    @objc private func clickFeedbackChanged() {
        SettingsStore.shared.clickFeedback = clickFeedbackCheckbox.state == .on
    }

    @objc private func radiusChanged() {
        SettingsStore.shared.radius = CGFloat(radiusSlider.doubleValue)
    }

    @objc private func borderWidthChanged() {
        SettingsStore.shared.borderWidth = CGFloat(borderWidthSlider.doubleValue)
    }

    @objc private func innerOpacityChanged() {
        SettingsStore.shared.innerOpacity = CGFloat(innerOpacitySlider.doubleValue)
    }

    @objc private func colorChanged() {
        SettingsStore.shared.color = colorWell.color
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

final class AboutWindowController: NSWindowController {
    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Screen Cursor"
        window.center()
        super.init(window: window)
        buildContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildContent() {
        guard let window else { return }

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let title = NSTextField(labelWithString: "Screen Cursor")
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.alignment = .center

        let version = NSTextField(labelWithString: "Version v\(Self.appVersion)")
        version.font = .systemFont(ofSize: 13, weight: .regular)
        version.textColor = .secondaryLabelColor
        version.alignment = .center

        let credits = NSTextField(labelWithString: "(c) 2026 Mathias Conradt")
        credits.font = .systemFont(ofSize: 12, weight: .regular)
        credits.textColor = .secondaryLabelColor
        credits.alignment = .center

        let license = NSTextField(labelWithString: "Licensed under the MIT License")
        license.font = .systemFont(ofSize: 12, weight: .regular)
        license.textColor = .secondaryLabelColor
        license.alignment = .center

        [title, version, credits, license].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 34),
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            version.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            version.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            version.trailingAnchor.constraint(equalTo: title.trailingAnchor),

            credits.topAnchor.constraint(equalTo: version.bottomAnchor, constant: 24),
            credits.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            credits.trailingAnchor.constraint(equalTo: title.trailingAnchor),

            license.topAnchor.constraint(equalTo: credits.bottomAnchor, constant: 6),
            license.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            license.trailingAnchor.constraint(equalTo: title.trailingAnchor)
        ])
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var toggleMenuItem: NSMenuItem?
    private let overlayController = OverlayController()
    private let settingsWindowController = SettingsWindowController()
    private let aboutWindowController = AboutWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        overlayController.start()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshToggleTitle),
            name: .screenCursorSettingsChanged,
            object: nil
        )
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.title = ""
        item.button?.image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Screen Cursor")
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Show Settings", action: #selector(showSettings), keyEquivalent: ","))
        let toggleItem = NSMenuItem(title: "", action: #selector(toggleHighlight), keyEquivalent: "")
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Screen Cursor", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu
        toggleMenuItem = toggleItem
        refreshToggleTitle()
        statusItem = item
    }

    @objc private func showSettings() {
        settingsWindowController.show()
    }

    @objc private func showAbout() {
        aboutWindowController.show()
    }

    @objc private func toggleHighlight(_ sender: NSMenuItem) {
        SettingsStore.shared.enabled.toggle()
    }

    @objc private func refreshToggleTitle() {
        toggleMenuItem?.title = SettingsStore.shared.enabled ? "Disable Highlight" : "Enable Highlight"
    }

    @objc private func quit() {
        overlayController.stop()
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
