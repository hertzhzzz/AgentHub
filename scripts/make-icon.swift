#!/usr/bin/env swift
// Draws the AgentHub app icon and builds Resources/AppIcon.icns.
import AppKit
import Foundation

let size = 1024
let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let work = FileManager.default.temporaryDirectory.appendingPathComponent("agenthub-icon-\(UUID().uuidString)")
let iconset = work.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func hex(_ v: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: a)
}

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fatalError("context") }

// Apple template: 824pt squircle centred on the 1024 canvas.
let inset: CGFloat = 100
let rect = CGRect(x: inset, y: inset, width: 824, height: 824)
let squircle = CGPath(roundedRect: rect, cornerWidth: 186, cornerHeight: 186, transform: nil)

// Soft drop shadow under the tile.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 24, color: hex(0x000000, 0.30))
ctx.addPath(squircle); ctx.setFillColor(hex(0x3B3FD8)); ctx.fillPath()
ctx.restoreGState()

// Gradient body.
ctx.saveGState()
ctx.addPath(squircle); ctx.clip()
let grad = CGGradient(colorsSpace: cs, colors: [hex(0x3B3FD8), hex(0x7A5CFF)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: rect.maxY), end: CGPoint(x: 0, y: rect.minY), options: [])

// Hub glyph with a soft shadow.
let c = CGPoint(x: 512, y: 512)
let dist: CGFloat = 235
let angles: [CGFloat] = [90, -30, 210].map { $0 * .pi / 180 }
let sats = angles.map { CGPoint(x: c.x + dist * cos($0), y: c.y + dist * sin($0)) }
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 14, color: hex(0x1A1C6E, 0.45))
ctx.setStrokeColor(hex(0xFFFFFF)); ctx.setLineWidth(24); ctx.setLineCap(.round)
for p in sats { ctx.move(to: c); ctx.addLine(to: p); ctx.strokePath() }
ctx.setFillColor(hex(0xFFFFFF))
ctx.fillEllipse(in: CGRect(x: c.x - 82, y: c.y - 82, width: 164, height: 164))
for p in sats { ctx.fillEllipse(in: CGRect(x: p.x - 52, y: p.y - 52, width: 104, height: 104)) }
ctx.restoreGState()

// Inner shadow: dark ring outside the squircle casts light shadow inward.
ctx.saveGState()
let ring = CGMutablePath()
ring.addRect(CGRect(x: -200, y: -200, width: 1424, height: 1424))
ring.addPath(squircle)
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 26, color: hex(0x0A0B50, 0.45))
ctx.addPath(ring); ctx.setFillColor(hex(0x000000)); ctx.fillPath(using: .evenOdd)
ctx.restoreGState()
ctx.restoreGState()

// Top highlight rim.
ctx.saveGState()
ctx.addPath(squircle); ctx.clip()
ctx.setStrokeColor(hex(0xFFFFFF, 0.18)); ctx.setLineWidth(3)
ctx.addPath(CGPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerWidth: 184, cornerHeight: 184, transform: nil))
ctx.strokePath()
ctx.restoreGState()

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
let master = work.appendingPathComponent("icon_1024.png")
try rep.representation(using: .png, properties: [:])!.write(to: master)

func run(_ tool: String, _ args: [String]) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: tool)
    p.arguments = args
    p.standardOutput = FileHandle.nullDevice
    try! p.run(); p.waitUntilExit()
    if p.terminationStatus != 0 { fatalError("\(tool) failed") }
}

let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in sizes {
    run("/usr/bin/sips", ["-z", "\(px)", "\(px)", master.path, "--out", iconset.appendingPathComponent("\(name).png").path])
}
let out = repo.appendingPathComponent("Resources/AppIcon.icns")
try FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
run("/usr/bin/iconutil", ["-c", "icns", iconset.path, "-o", out.path])
    
print("Wrote \(out.path)")
