#!/usr/bin/env swift

import AppKit

// MARK: - App icon

func generateAppIcon(size: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    let s = CGFloat(size)
    let ctx = NSGraphicsContext.current!.cgContext

    // --- Background: rounded rect with gradient ---
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgRadius = s * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: bgRadius, cornerHeight: bgRadius, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        CGColor(red: 0.20, green: 0.50, blue: 0.95, alpha: 1.0),
        CGColor(red: 0.40, green: 0.25, blue: 0.85, alpha: 1.0),
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    ctx.restoreGState()

    // --- Stacked windows (rectangle.stack style) ---
    let lineW = s * 0.024
    let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)

    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Front window — large, centered in the icon
    let winW = s * 0.64
    let winH = s * 0.46
    let winRadius = s * 0.065
    let winX = (s - winW) / 2
    let winY = (s - winH) / 2 - s * 0.06  // slightly below center to make room for arcs

    // --- Back arcs: only the top curved border peeking above the front window ---
    let arcGap = s * 0.055        // even vertical spacing between each arc
    let arcShrink = s * 0.04      // narrower per level on each side

    for level in (1...2).reversed() {
        let lf = CGFloat(level)
        let arcW = winW - lf * arcShrink * 2
        let arcRadius = winRadius * (arcW / winW)

        // Position: just the top edge visible above the front window, evenly spaced
        let arcCenterX = s / 2
        let arcTopY = winY + winH + lf * arcGap

        // Draw a single arc (the top border of a rounded rect)
        ctx.saveGState()
        let alpha: CGFloat = level == 2 ? 0.35 : 0.55
        ctx.setStrokeColor(white.copy(alpha: alpha)!)
        ctx.setLineWidth(lineW)

        // Arc from left corner to right corner across the top
        let arcLeft = arcCenterX - arcW / 2
        let arcRight = arcCenterX + arcW / 2
        let arcBaseY = arcTopY - arcRadius

        ctx.move(to: CGPoint(x: arcLeft, y: arcBaseY))
        ctx.addArc(tangent1End: CGPoint(x: arcLeft, y: arcTopY),
                   tangent2End: CGPoint(x: arcLeft + arcRadius, y: arcTopY),
                   radius: arcRadius)
        ctx.addLine(to: CGPoint(x: arcRight - arcRadius, y: arcTopY))
        ctx.addArc(tangent1End: CGPoint(x: arcRight, y: arcTopY),
                   tangent2End: CGPoint(x: arcRight, y: arcBaseY),
                   radius: arcRadius)
        ctx.strokePath()
        ctx.restoreGState()
    }

    // --- Front window ---
    let winRect = CGRect(x: winX, y: winY, width: winW, height: winH)
    let winPath = CGPath(roundedRect: winRect, cornerWidth: winRadius, cornerHeight: winRadius, transform: nil)

    // Fill to cleanly cover any arc overlap
    let fillColor = CGColor(red: 0.28, green: 0.38, blue: 0.88, alpha: 1.0)
    ctx.setFillColor(fillColor)
    ctx.addPath(winPath)
    ctx.fillPath()

    // Stroke
    ctx.setStrokeColor(white)
    ctx.setLineWidth(lineW)
    ctx.addPath(winPath)
    ctx.strokePath()

    // --- Three traffic-light dots ---
    let dotR = s * 0.019
    let dotY = winRect.maxY - winRadius - dotR * 0.2
    let dotStartX = winRect.minX + winRadius + dotR * 1.0
    let dotSpacing = dotR * 3.5

    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
    for i in 0..<3 {
        let cx = dotStartX + CGFloat(i) * dotSpacing
        ctx.fillEllipse(in: CGRect(x: cx - dotR, y: dotY - dotR, width: dotR * 2, height: dotR * 2))
    }

    img.unlockFocus()
    return img
}

// MARK: - Save helper

func savePNG(_ image: NSImage, to path: String, pixelSize: Int) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

// MARK: - Generate

let appIconDir = "Assets.xcassets/AppIcon.appiconset"

let appSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for entry in appSizes {
    let icon = generateAppIcon(size: entry.pixels)
    let path = "\(appIconDir)/\(entry.name).png"
    savePNG(icon, to: path, pixelSize: entry.pixels)
    print("Generated \(path)")
}

print("Done!")
