#if canImport(PaperKit)
import PaperKit
import Foundation

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

@available(iOS 26.0, macOS 26.0, *)
extension ExpoPaperkitView {

  func loadInitialData(_ base64String: String) {
    guard base64String != lastLoadedInitialData else { return }
    guard let data = Data(base64Encoded: base64String) else { return }
    do {
      let markup = try PaperMarkup(dataRepresentation: data)
      state.markup = markup
      state.viewController?.markup = markup
      lastLoadedInitialData = base64String
    } catch {
      NSLog("[ExpoPaperkit] Failed to load initial data: %@", error.localizedDescription)
    }
  }

  func save() async throws -> String {
    guard let markup = state.viewController?.markup else {
      throw PaperkitError.noMarkupData
    }
    let data = try await markup.dataRepresentation()
    return data.base64EncodedString()
  }

  func clearMarkup() {
    guard bounds.width > 0, bounds.height > 0 else { return }
    let markup = PaperMarkup(bounds: currentCanvasBounds())
    state.markup = markup
    state.viewController?.markup = markup
    lastLoadedInitialData = nil

#if !os(macOS)
    restoreToolPickerAfterClear()
#endif
  }

  func performUndo() {
    state.viewController?.undoManager?.undo()
  }

  func performRedo() {
    state.viewController?.undoManager?.redo()
  }

  func exportAsImage(format: String, quality: Double, includeBackground: Bool) async throws -> String {
    guard let markup = state.viewController?.markup ?? state.markup else {
      throw PaperkitError.noMarkupData
    }

    let renderBounds = markup.bounds

    guard renderBounds.width > 0, renderBounds.height > 0 else {
      throw PaperkitError.exportFailed("Markup bounds are empty")
    }

    let background = includeBackground ? normalizedBackgroundImage() : nil

#if !os(macOS)
    let screenScale = UIScreen.main.scale
#else
    let screenScale = NSScreen.main?.backingScaleFactor ?? 2.0
#endif

    let outputSize = background.map { backgroundPixelSize($0) }
      ?? CGSize(width: renderBounds.width * screenScale, height: renderBounds.height * screenScale)

    let pixelWidth = Int(outputSize.width.rounded())
    let pixelHeight = Int(outputSize.height.rounded())

    guard pixelWidth > 0, pixelHeight > 0 else {
      throw PaperkitError.exportFailed("Computed an empty output size")
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard let ctx = CGContext(
      data: nil,
      width: pixelWidth,
      height: pixelHeight,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    ) else {
      throw PaperkitError.exportFailed("Failed to create bitmap context")
    }

    if let background = background, let backgroundImage = backgroundCGImage(from: background) {
      ctx.draw(backgroundImage, in: CGRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight)))
    }

    let markupRect: CGRect

    if let background = background {
      markupRect = contentRect(
        forImageSize: backgroundPixelSize(background),
        in: renderBounds,
        contentMode: backgroundImageContentMode
      )
    } else {
      markupRect = renderBounds
    }

    ctx.translateBy(x: 0, y: CGFloat(pixelHeight))
    ctx.scaleBy(x: 1, y: -1)
    ctx.scaleBy(x: CGFloat(pixelWidth) / markupRect.width, y: CGFloat(pixelHeight) / markupRect.height)
    ctx.translateBy(x: -markupRect.origin.x, y: -markupRect.origin.y)

#if !os(macOS)
    let options = RenderingOptions(traitCollection: UITraitCollection.current)
#else
    let options = RenderingOptions()
#endif
    await markup.draw(in: ctx, frame: renderBounds, options: options)

    guard let cgImage = ctx.makeImage() else {
      throw PaperkitError.exportFailed("Failed to create image from context")
    }

    let ext = format == "jpg" ? "jpg" : "png"

#if !os(macOS)
    let image = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    let imageData: Data? = format == "jpg"
      ? image.jpegData(compressionQuality: quality)
      : image.pngData()
#else
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    let imageData: Data? = format == "jpg"
      ? bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
      : bitmapRep.representation(using: .png, properties: [:])
#endif

    guard let data = imageData else {
      throw PaperkitError.exportFailed("Failed to generate image data")
    }

    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "paperkit_export_\(UUID().uuidString).\(ext)"
    let fileURL = tempDir.appendingPathComponent(fileName)
    try data.write(to: fileURL)
    return fileURL.absoluteString
  }

  private func contentRect(forImageSize imageSize: CGSize, in bounds: CGRect, contentMode: String) -> CGRect {
    guard contentMode == "contain", imageSize.width > 0, imageSize.height > 0 else { return bounds }

    let fitScale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
    let fittedSize = CGSize(width: imageSize.width * fitScale, height: imageSize.height * fitScale)

    return CGRect(
      x: bounds.origin.x + (bounds.width - fittedSize.width) / 2,
      y: bounds.origin.y + (bounds.height - fittedSize.height) / 2,
      width: fittedSize.width,
      height: fittedSize.height
    )
  }

#if !os(macOS)
  private func normalizedBackgroundImage() -> UIImage? {
    guard let image = (state.viewController?.contentView as? UIImageView)?.image else { return nil }
    guard image.imageOrientation != .up else { return image }

    let format = UIGraphicsImageRendererFormat.default()
    format.scale = image.scale

    return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
  }

  private func backgroundPixelSize(_ image: UIImage) -> CGSize {
    CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
  }

  private func backgroundCGImage(from image: UIImage) -> CGImage? {
    image.cgImage
  }
#else
  private func normalizedBackgroundImage() -> NSImage? {
    (state.viewController?.contentView as? NSImageView)?.image
  }

  private func backgroundPixelSize(_ image: NSImage) -> CGSize {
    guard let rep = image.representations.first else { return image.size }
    return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
  }

  private func backgroundCGImage(from image: NSImage) -> CGImage? {
    image.cgImage(forProposedRect: nil, context: nil, hints: nil)
  }
#endif
}


#else

// MARK: - Stubs (PaperKit unavailable)

extension ExpoPaperkitView {
  func loadInitialData(_ base64String: String) {}
  func save() async throws -> String { throw PaperkitError.unsupportedPlatform }
  func clearMarkup() {}
  func performUndo() {}
  func performRedo() {}
  func presentMarkupTools() {}
  func exportAsImage(format: String, quality: Double, includeBackground: Bool) async throws -> String {
    throw PaperkitError.unsupportedPlatform
  }
}

#endif
