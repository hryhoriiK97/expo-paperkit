import { requireNativeView } from 'expo';
import React, { forwardRef, useCallback, useImperativeHandle, useMemo, useRef } from 'react';

import type {
  PaperMarkupRef,
  PaperMarkupViewProps,
  FeatureSetConfig,
  ToolPickerVisibility,
} from './ExpoPaperkit.types';

const DEFAULT_FEATURE_SET: Required<FeatureSetConfig> = {
  shapes: true,
  textBoxes: true,
  arrows: true,
  hdr: false,
};

type NativeProps = Omit<
  PaperMarkupViewProps,
  'onMarkupChanged' | 'onSelectionChanged' | 'onContentVisibleFrameChanged' | 'featureSet'
> & {
  featureSet: Required<FeatureSetConfig>;
  onMarkupChanged: () => void;
  onSelectionChanged: (event: { nativeEvent: { hasSelection: boolean } }) => void;
  onContentVisibleFrameChanged: (event: {
    nativeEvent: { x: number; y: number; width: number; height: number };
  }) => void;
};

const NativeView: React.ComponentType<NativeProps & { ref: React.Ref<any> }> =
  requireNativeView('ExpoPaperkit');

export const PaperMarkupView = forwardRef<PaperMarkupRef, PaperMarkupViewProps>(
  (
    {
      featureSet,
      onMarkupChanged,
      onSelectionChanged,
      onDrawingBegan,
      onContentVisibleFrameChanged,
      ...props
    },
    ref
  ) => {
    const nativeRef = useRef<any>(null);

    useImperativeHandle(ref, () => ({
      save: () => nativeRef.current?.save() ?? Promise.reject(new Error('View not mounted')),
      exportAsImage: (format: 'png' | 'jpg' = 'png', quality = 0.9, includeBackground = true) =>
        nativeRef.current?.exportAsImage(format, quality, includeBackground) ??
        Promise.reject(new Error('View not mounted')),
      clear: () => nativeRef.current?.clear(),
      undo: () => nativeRef.current?.undo(),
      redo: () => nativeRef.current?.redo(),
      showMarkupTools: () => nativeRef.current?.showMarkupTools(),
      setToolPickerVisibility: (visibility: ToolPickerVisibility) =>
        nativeRef.current?.setToolPickerVisibility(visibility),
    }));

    const handleMarkupChanged = useCallback(() => {
      onMarkupChanged?.();
    }, [onMarkupChanged]);

    const handleSelectionChanged = useCallback(
      (e: { nativeEvent: { hasSelection: boolean } }) => {
        onSelectionChanged?.(e.nativeEvent);
      },
      [onSelectionChanged]
    );

    const handleDrawingBegan = useCallback(() => {
      onDrawingBegan?.();
    }, [onDrawingBegan]);

    const handleContentVisibleFrameChanged = useCallback(
      (e: { nativeEvent: { x: number; y: number; width: number; height: number } }) => {
        onContentVisibleFrameChanged?.(e.nativeEvent);
      },
      [onContentVisibleFrameChanged]
    );

    const resolvedFeatureSet = useMemo<Required<FeatureSetConfig>>(
      () => ({
        ...DEFAULT_FEATURE_SET,
        ...featureSet,
      }),
      [featureSet?.shapes, featureSet?.textBoxes, featureSet?.arrows, featureSet?.hdr]
    );

    return (
      <NativeView
        ref={nativeRef}
        {...props}
        featureSet={resolvedFeatureSet}
        onMarkupChanged={handleMarkupChanged}
        onSelectionChanged={handleSelectionChanged}
        onDrawingBegan={handleDrawingBegan}
        onContentVisibleFrameChanged={handleContentVisibleFrameChanged}
      />
    );
  }
);
