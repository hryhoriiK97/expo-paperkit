import ExpoModulesCore

public class ExpoPaperkitModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoPaperkit")

    View(ExpoPaperkitView.self) {

      // MARK: - Props

      Prop("showToolbar") { (view: ExpoPaperkitView, value: Bool) in
        view.showToolbar = value
      }

      Prop("readOnly") { (view: ExpoPaperkitView, value: Bool) in
        view.readOnly = value
      }

      Prop("showPencilKit") { (view: ExpoPaperkitView, value: Bool) in
        view.showPencilKit = value
      }

      Prop("allowFingerDrawing") { (view: ExpoPaperkitView, value: Bool) in
        view.allowFingerDrawing = value
      }

      Prop("initialData") { (view: ExpoPaperkitView, value: String?) in
        if let base64 = value, !base64.isEmpty {
          if #available(iOS 26.0, macOS 26.0, *) {
            view.loadInitialData(base64)
          }
        }
      }

      Prop("backgroundImageUri") { (view: ExpoPaperkitView, value: String?) in
        view.backgroundImageUri = value
      }

      Prop("backgroundImageContentMode") { (view: ExpoPaperkitView, value: String?) in
        view.backgroundImageContentMode = value ?? "cover"
      }

      Prop("featureSet") { (view: ExpoPaperkitView, config: FeatureSetConfig?) in
        if let config = config {
          view.featureSetConfig = config
        }
      }

      Prop("canvasSize") { (view: ExpoPaperkitView, value: CanvasSizeConfig?) in
        if let size = value {
          view.canvasWidth = size.width
          view.canvasHeight = size.height
        }
      }

      Prop("minZoomScale") { (view: ExpoPaperkitView, value: Double?) in
        view.minZoomScale = value ?? 0.25
      }

      Prop("maxZoomScale") { (view: ExpoPaperkitView, value: Double?) in
        view.maxZoomScale = value ?? 4.0
      }

      Prop("toolPickerVisibility") { (view: ExpoPaperkitView, value: String?) in
        view.toolPickerVisibilityProp = value ?? "visible"
      }

      Prop("isRulerActive") { (view: ExpoPaperkitView, value: Bool) in
        view.isRulerActive = value
      }

      Prop("directTouchAutomaticallyDraws") { (view: ExpoPaperkitView, value: Bool) in
        view.directTouchAutomaticallyDraws = value
      }

      Prop("indirectPointerTouchMode") { (view: ExpoPaperkitView, value: String?) in
        view.indirectPointerTouchMode = value ?? "drawing"
      }

      Prop("canvasBackgroundColor") { (view: ExpoPaperkitView, value: UIColor?) in
        view.canvasBackgroundColor = value
      }

      // MARK: - Events

      Events(
        "onMarkupChanged",
        "onSelectionChanged",
        "onDrawingBegan",
        "onContentVisibleFrameChanged"
      )

      // MARK: - View Functions

      AsyncFunction("save") { (view: ExpoPaperkitView) -> String in
        if #available(iOS 26.0, macOS 26.0, *) {
          return try await view.save()
        }
        throw PaperkitError.unsupportedPlatform
      }

      AsyncFunction("exportAsImage") { (view: ExpoPaperkitView, format: String, quality: Double, includeBackground: Bool?) -> String in
        if #available(iOS 26.0, macOS 26.0, *) {
          return try await view.exportAsImage(format: format, quality: quality, includeBackground: includeBackground ?? true)
        }
        throw PaperkitError.unsupportedPlatform
      }

      AsyncFunction("clear") { (view: ExpoPaperkitView) in
        if #available(iOS 26.0, macOS 26.0, *) {
          view.clearMarkup()
        }
      }

      AsyncFunction("undo") { (view: ExpoPaperkitView) in
        if #available(iOS 26.0, macOS 26.0, *) {
          view.performUndo()
        }
      }

      AsyncFunction("redo") { (view: ExpoPaperkitView) in
        if #available(iOS 26.0, macOS 26.0, *) {
          view.performRedo()
        }
      }

      AsyncFunction("showMarkupTools") { (view: ExpoPaperkitView) in
        if #available(iOS 26.0, macOS 26.0, *) {
          view.presentMarkupTools()
        }
      }

      AsyncFunction("setToolPickerVisibility") { (view: ExpoPaperkitView, visibility: String) in
        if #available(iOS 26.0, macOS 26.0, *) {
          view.setToolPickerVisibility(visibility)
        }
      }
    }
  }
}
