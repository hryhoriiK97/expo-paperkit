import type { ColorValue, StyleProp, ViewStyle } from 'react-native';

export interface FeatureSetConfig {
  /**
   * Enable shape tools (rectangle, ellipse, star, rounded rectangle, etc.).
   * @default true
   * @platform ios, macos
   */
  shapes?: boolean;
  /**
   * Enable text box insertion.
   * @default true
   * @platform ios, macos
   */
  textBoxes?: boolean;
  /**
   * Enable arrow/line tools and line marker positions.
   * When disabled, removes arrow shapes, line shapes, and all line markers.
   * @default true
   * @platform ios, macos
   */
  arrows?: boolean;
  /**
   * Enable HDR (extended dynamic range) color support.
   * When disabled, limits color exposure to standard dynamic range (1.0).
   * @default false
   * @platform ios, macos
   */
  hdr?: boolean;
}

/**
 * Visibility state of the tool picker.
 * - `'visible'` — tool picker is shown and active
 * - `'hidden'` — tool picker is hidden but can be restored
 * - `'inactive'` — tool picker is deactivated
 */
export type ToolPickerVisibility = 'visible' | 'hidden' | 'inactive';

/**
 * Touch interaction mode for indirect pointer (trackpad/mouse) or direct touch input.
 * - `'drawing'` — pointer/touch draws on the canvas
 * - `'selection'` — pointer/touch selects and pans
 */
export type TouchMode = 'drawing' | 'selection';

/**
 * Content mode for the background image.
 * - `'cover'` — scales to fill the canvas, cropping edges if needed
 * - `'contain'` — scales to fit within the canvas, preserving aspect ratio
 * - `'stretch'` — stretches to fill the canvas exactly, ignoring aspect ratio
 */
export type BackgroundImageContentMode = 'cover' | 'contain' | 'stretch';

export interface PaperMarkupRef {
  /**
   * Serialize the current markup to a base64-encoded string.
   * The returned data can be stored and passed back via `initialData` to restore.
   * @platform ios, macos
   */
  save(): Promise<string>;
  /**
   * Export the canvas as a rasterized image file.
   * @param format - Image format: `'png'` or `'jpg'`.
   * @param quality - Compression quality for JPEG (0.0–1.0). Ignored for PNG.
   * @returns File URI of the exported image.
   * @platform ios, macos
   */
  exportAsImage(
    format: 'png' | 'jpg',
    quality?: number,
    includeBackground?: boolean
  ): Promise<string>;
  /**
   * Remove all markup content from the canvas.
   * @platform ios, macos
   */
  clear(): Promise<void>;
  /**
   * Undo the last action.
   * @platform ios, macos
   */
  undo(): Promise<void>;
  /**
   * Redo the last undone action.
   * @platform ios, macos
   */
  redo(): Promise<void>;
  /**
   * Present the markup insertion tools UI.
   * On iOS, shows a popover with shape/text/line options.
   * On macOS, ensures the toolbar is visible.
   * @platform ios, macos
   */
  showMarkupTools(): Promise<void>;
  /**
   * Programmatically show or hide the tool picker at runtime.
   * @platform ios
   */
  setToolPickerVisibility(visibility: ToolPickerVisibility): Promise<void>;
}

export interface CanvasSize {
  /** Canvas width in points. */
  width: number;
  /** Canvas height in points. */
  height: number;
}

export interface PaperMarkupViewProps {
  /**
   * Show the native markup toolbar.
   * On macOS, displays the `MarkupToolbarViewController` at the bottom.
   * @default true
   * @platform macos
   */
  showToolbar?: boolean;
  /**
   * Disable all editing. The canvas becomes view-only.
   * @default false
   * @platform ios, macos
   */
  readOnly?: boolean;
  /**
   * Show the floating PKToolPicker for drawing tool selection.
   * @default true
   * @platform ios
   */
  showPencilKit?: boolean;
  /**
   * Allow finger input to draw on the canvas.
   * By default, finger input is used for selection/panning on iOS.
   * @default false
   * @platform ios
   */
  allowFingerDrawing?: boolean;
  /**
   * Base64-encoded markup data to restore.
   * Typically the output of a previous `save()` call.
   * @platform ios, macos
   */
  initialData?: string;
  /**
   * URI for a background image displayed behind the markup content.
   * Supports `http://`, `https://`, and local `file://` paths.
   * @platform ios, macos
   */
  backgroundImageUri?: string;
  /**
   * How the background image is scaled within the canvas.
   * @default 'cover'
   * @platform ios, macos
   */
  backgroundImageContentMode?: BackgroundImageContentMode;
  /**
   * Configure which PaperKit features are available on the canvas.
   * @default { shapes: true, textBoxes: true, arrows: true, hdr: false }
   * @platform ios, macos
   */
  featureSet?: FeatureSetConfig;
  /**
   * Size of the paper canvas in points. Defaults to the view's size.
   * @platform ios, macos
   */
  canvasSize?: CanvasSize;
  /**
   * Minimum zoom scale factor.
   * @default 0.25
   * @platform ios, macos
   */
  minZoomScale?: number;
  /**
   * Maximum zoom scale factor.
   * @default 4.0
   * @platform ios, macos
   */
  maxZoomScale?: number;
  /**
   * Show the ruler overlay on the canvas.
   * @default false
   * @platform ios
   */
  isRulerActive?: boolean;
  /**
   * Let the system decide when direct touches should draw vs. select
   * based on context (e.g., Apple Pencil presence).
   * @default false
   * @platform ios
   */
  directTouchAutomaticallyDraws?: boolean;
  /**
   * Controls trackpad/mouse behavior.
   * - `'drawing'` — pointer draws on the canvas
   * - `'selection'` — pointer selects and pans
   * @default 'drawing'
   * @platform ios, macos
   */
  indirectPointerTouchMode?: TouchMode;
  /**
   * Control the visibility state of the PKToolPicker.
   * @default 'visible'
   * @platform ios
   */
  toolPickerVisibility?: ToolPickerVisibility;
  /**
   * Background color of the native canvas view.
   * Accepts hex strings, named CSS colors, `rgb()`/`rgba()`, or `'transparent'`.
   * @platform ios, macos
   */
  canvasBackgroundColor?: ColorValue;
  /**
   * Fired when the markup content changes (stroke completed, element added/removed/modified).
   * @platform ios, macos
   */
  onMarkupChanged?: () => void;
  /**
   * Fired when the selection state changes.
   * @platform ios, macos
   */
  onSelectionChanged?: (event: { hasSelection: boolean }) => void;
  /**
   * Fired when the user begins a drawing stroke.
   * @platform ios, macos
   */
  onDrawingBegan?: () => void;
  /**
   * Fired when the user scrolls or zooms the canvas content.
   * @platform ios, macos
   */
  onContentVisibleFrameChanged?: (event: {
    x: number;
    y: number;
    width: number;
    height: number;
  }) => void;
  /**
   * Standard React Native view style for the component container.
   * @platform ios, macos
   */
  style?: StyleProp<ViewStyle>;
}
