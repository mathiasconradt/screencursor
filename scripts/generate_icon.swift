#!/usr/bin/env swift
import Cocoa

func renderPNG(size: Int) -> Data {
    let s = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    // Dark rounded-rect background
    let r = s * 0.225
    let bg = CGMutablePath()
    bg.addRoundedRect(in: CGRect(x: 0, y: 0, width: s, height: s), cornerWidth: r, cornerHeight: r)
    ctx.setFillColor(CGColor(srgbRed: 0.08, green: 0.08, blue: 0.14, alpha: 1))
    ctx.addPath(bg)
    ctx.fillPath()

    // Clip subsequent drawing to background shape so shadow can't bleed outside
    ctx.addPath(bg)
    ctx.clip()

    // Arrow cursor path — normalized (0…1) coordinates, y-up
    let mg = s * 0.13
    let aw = s - 2 * mg

    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: mg + x * aw, y: mg + y * aw)
    }

    // Classic Mac cursor — 5 vertices, close = left vertical edge
    // From tip: right diagonal down → notch steps LEFT+DOWN (concave) → tail right → tail bottom → close (left edge up)
    // Notch y MUST be below outer-right y (in y-up) to get correct concave direction
    let arrow = CGMutablePath()
    arrow.move(to: pt(0.20, 0.90))      // TIP (upper-left)
    arrow.addLine(to: pt(0.80, 0.45))   // outer-right: widest point of arrowhead
    arrow.addLine(to: pt(0.54, 0.36))   // notch: step left+down (concave inward)
    arrow.addLine(to: pt(0.35, 0.10))   // tail bottom-right
    arrow.addLine(to: pt(0.20, 0.10))   // tail bottom-left
    arrow.closeSubpath()                 // close = left edge straight UP to tip ✓

    // Drop shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: s * 0.010, height: -s * 0.015),
        blur: s * 0.040,
        color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.65)
    )
    ctx.setFillColor(CGColor(srgbRed: 0.18, green: 0.82, blue: 0.38, alpha: 1.0))
    ctx.addPath(arrow)
    ctx.fillPath()
    ctx.restoreGState()

    // White outline for crispness
    ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.75))
    ctx.setLineWidth(max(1.0, s * 0.020))
    ctx.setLineJoin(.miter)
    ctx.addPath(arrow)
    ctx.strokePath()

    let img = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: img)
    return rep.representation(using: .png, properties: [:])!
}

let iconset = "Resources/AppIcon.iconset"
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let specs: [(String, Int)] = [
    ("icon_16x16.png",      16),
    ("icon_16x16@2x.png",   32),
    ("icon_32x32.png",      32),
    ("icon_32x32@2x.png",   64),
    ("icon_128x128.png",   128),
    ("icon_128x128@2x.png",256),
    ("icon_256x256.png",   256),
    ("icon_256x256@2x.png",512),
    ("icon_512x512.png",   512),
    ("icon_512x512@2x.png",1024),
]

for (name, size) in specs {
    try! renderPNG(size: size).write(to: URL(fileURLWithPath: "\(iconset)/\(name)"))
    print("  \(name)")
}
