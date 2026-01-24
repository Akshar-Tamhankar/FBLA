
// FBLA/UI/Background3DView.swift
// Swift 6 • iOS 17+
//
///  Animated, dynamic "bubbles + gold accents" background (pure SwiftUI).
///
///  - Passively animated via `TimelineView` (not tied to swipes).
///  - Renders in linear color space to reduce banding.
///  - Adds static dither to eliminate residual posterization.
///  - Honors Light/Dark and Reduce Motion.
///
///  ### Performance
///  - Uses offscreen `drawingGroup(colorMode: .linear)` for smoother gradients.
///  - Grain layer is static (no shimmering).
///  - Motion reduces when `Reduce Motion` is enabled.
///
import SwiftUI
import UIKit

/// Premium animated background with haze and gold accents.
struct Background3DView: View {
    /// Kept for API parity; not used for animation drivers.
    @Binding var pageIndex: Int
    /// Kept for API parity; not used for animation drivers.
    @Binding var swipeProgress: Double
    /// Optional override for color scheme; otherwise uses environment.
    var colorScheme: ColorScheme? = nil

    @Environment(\.colorScheme) private var envScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Tunables — haze orbs
    private let bubbleCount = 14
    private let baseRadius: CGFloat = 196
    private let hazeBlur: CGFloat = 84
    private let baseXAmplitude: CGFloat = 0.48
    private let baseYAmplitude: CGFloat = 0.36
    private let fieldAmplitude: CGFloat = 90

    // Tunables — gold flecks
    private let goldCount = 34
    private let goldBlur: CGFloat = 26
    private let goldMinR: CGFloat = 16
    private let goldMaxR: CGFloat = 26

    // Tunables — static grain
    private let grainCount = 900
    private let grainOpacity: CGFloat = 0.055

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Canvas { ctx, size in
                    let scheme = colorScheme ?? envScheme

                    // Base palette (gentle breathing between navy and light blue).
                    let navy = ThemeColor.navy
                    let lightBlue = Color(hue: 210/360, saturation: 0.65, brightness: scheme == .dark ? 0.85 : 0.95)
                    let blend = CGFloat(0.25 + 0.08 * sin(t * 0.010))
                    let c1 = navy.mix(with: lightBlue, amount: blend)
                    let c2 = lightBlue.mix(with: navy, amount: 1 - blend)
                    let edgeFade = scheme == .dark ? 0.78 : 0.88

                    // Haze layer (blurred).
                    ctx.drawLayer { layer in
                        layer.addFilter(.blur(radius: hazeBlur))
                        layer.blendMode = .plusLighter

                        for i in 0..<bubbleCount {
                            let seed = Double(i + 1)
                            let baseSpeed = 0.092 + 0.020 * seed
                            let speed = reduceMotion ? 0.030 : baseSpeed
                            let eased = easeInOutSine((sin(t * speed * 0.24) + 1.0) * 0.5)
                            let angle = (t * speed * 0.56) + eased * .pi * 0.28
                            let x0 = 0.5 + baseXAmplitude * sin(angle + seed * 0.7)
                            let y0 = 0.5 + baseYAmplitude * cos(angle * 0.9 + seed)

                            // Gentle curl-noise-like drift.
                            let flow = flowOffset(x: x0, y: y0, t: t, seed: seed)
                            let center = CGPoint(
                                x: size.width  * (x0 + (reduceMotion ? 0 : flow.dx)),
                                y: size.height * (y0 + (reduceMotion ? 0 : flow.dy))
                            )

                            let r = baseRadius * CGFloat(0.70 + 0.25 * sin(seed * 1.73))
                            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                            let path = Path(ellipseIn: rect)

                            let grad = Gradient(stops: [
                                .init(color: c1.opacity(0.95),                          location: 0.00),
                                .init(color: c1.opacity(0.70),                          location: 0.26),
                                .init(color: c1.mix(with: c2, amount: 0.5).opacity(0.52), location: 0.46),
                                .init(color: c2.opacity(0.40),                          location: 0.66),
                                .init(color: c2.opacity(0.00),                          location: edgeFade)
                            ])
                            let shading = GraphicsContext.Shading.radialGradient(grad, center: center, startRadius: 0, endRadius: r)
                            layer.fill(path, with: shading)
                        }
                    }

                    // Gold fleck layer (smaller, own blur).
                    ctx.drawLayer { layer in
                        layer.addFilter(.blur(radius: goldBlur))
                        layer.blendMode = .plusLighter

                        let goldCenter = Color(red: 1.00, green: 0.92, blue: 0.55)
                        let goldMid    = Color(red: 1.00, green: 0.86, blue: 0.22)

                        for i in 0..<goldCount {
                            let seed = Double(i + 1)
                            let s = reduceMotion ? 0.010 : 0.018
                            let a = t * s
                            let gx = 0.5 + 0.44 * sin(a + seed * 0.96) + 0.03 * sin(a * 0.36 + seed * 1.7)
                            let gy = 0.5 + 0.38 * cos(a * 0.92 + seed * 0.72) + 0.03 * cos(a * 0.33 + seed * 1.1)

                            let rBase = goldMinR + (goldMaxR - goldMinR) * CGFloat(0.5 + 0.5 * sin(seed * 1.21))
                            let r = max(goldMinR, min(goldMaxR, rBase))
                            let center = CGPoint(x: size.width * CGFloat(gx), y: size.height * CGFloat(gy))
                            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                            let path = Path(ellipseIn: rect)

                            let grad = Gradient(stops: [
                                .init(color: goldCenter.opacity(0.82), location: 0.0),
                                .init(color: goldMid.opacity(0.35),    location: 0.55),
                                .init(color: goldMid.opacity(0.00),    location: 1.0)
                            ])
                            let shading = GraphicsContext.Shading.radialGradient(grad, center: center, startRadius: 0, endRadius: r)
                            layer.fill(path, with: shading)
                        }
                    }
                }

                // Static grain (overlay).
                Canvas { ctx, size in
                    ctx.blendMode = .overlay
                    var rng = LCG(seed: 0xC0FFEE)
                    for _ in 0..<grainCount {
                        let x = CGFloat(rng.next()) * size.width
                        let y = CGFloat(rng.next()) * size.height
                        let r: CGFloat = 0.6
                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(grainOpacity)))
                    }
                }
                .allowsHitTesting(false)
            }
            .drawingGroup(opaque: false, colorMode: .linear)
        }
        .compositingGroup()
    }

    /// Gentle curl-noise-like drift field used by haze bubbles.
    private func flowOffset(x: CGFloat, y: CGFloat, t: Double, seed: Double) -> CGVector {
        let X = Double(x) * 2.0 * .pi
        let Y = Double(y) * 2.0 * .pi
        let u  = sin(X * 0.48 + t * 0.058 + seed * 0.7) * cos(Y * 0.44 - t * 0.052 + seed * 0.3)
        let v  = -cos(X * 0.42 - t * 0.052 + seed * 0.9) * sin(Y * 0.46 + t * 0.060 + seed * 0.4)
        let u2 = 0.50 * sin(X * 0.76 - t * 0.032 + seed * 1.3)
        let v2 = 0.50 * cos(Y * 0.72 + t * 0.038 + seed * 1.1)
        var fx = (u + u2), fy = (v + v2)
        let len = max(0.001, sqrt(fx * fx + fy * fy))
        fx /= len; fy /= len
        return CGVector(dx: CGFloat(fx) * (fieldAmplitude / 1000.0),
                        dy: CGFloat(fy) * (fieldAmplitude / 1000.0))
    }

    /// Smooth in/out for the breathing palette blend.
    private func easeInOutSine(_ x: Double) -> Double { 0.5 * (1 - cos(.pi * x)) }
}

// MARK: Tiny deterministic RNG for static dither (no shimmer)

private struct LCG {
    private var state: UInt32
    init(seed: UInt32) { self.state = seed }
    mutating func next() -> CGFloat {
        state = 1664525 &* state &+ 1013904223
        return CGFloat(Double(state) / Double(UInt32.max))
    }
}

// MARK: Theme fallback for background (isolated to avoid tight coupling)

private enum ThemeColor {
    static let navy = Color(.sRGB, red: 11/255, green: 45/255, blue: 107/255, opacity: 1)
}

// MARK: Simple color mixing helper (UIKit-bridged for accuracy)

private extension Color {
    func mix(with other: Color, amount: CGFloat) -> Color {
        let a = max(0, min(1, amount))
        let ui1 = UIColor(self), ui2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1c: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2c: CGFloat = 0
        ui1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1c)
        ui2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2c)
        return Color(red:     r1 + (r2 - r1) * a,
                     green:   g1 + (g2 - g1) * a,
                     blue:    b1 + (b2 - b1) * a,
                     opacity: a1c + (a2c - a1c) * a)
    }
}
