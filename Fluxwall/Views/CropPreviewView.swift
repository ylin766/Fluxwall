import SwiftUI

struct CropPreviewView: View {
    let displaySize: CGSize                         // Display resolution
    let previewImage: NSImage                       // Generated thumbnail
    
    @Binding var scale: CGFloat                     // Scale factor
    @Binding var offset: CGSize                     // Drag offset
    var onScaleChanged: ((CGFloat) -> Void)? = nil
    var onOffsetChanged: ((CGSize) -> Void)? = nil

    @GestureState private var dragOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 12) {
            // Screen simulator + thumbnail preview
            ComputerFrameView(displaySize: displaySize) {
                CropPreviewImage(
                    image: previewImage,
                    scale: scale,
                    offset: offset,
                    targetDisplaySize: displaySize
                )
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            // Calculate relative offset based on display size
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            lastOffset = newOffset
                            offset = newOffset
                            onOffsetChanged?(newOffset)
                        }
                )
                .onChange(of: dragOffset) { newDrag in
                    offset = CGSize(
                        width: lastOffset.width + newDrag.width,
                        height: lastOffset.height + newDrag.height
                    )
                }
            }
            .frame(height: 260)

            // Scale control slider + reset button
            VStack(spacing: 4) {
                HStack {
                    Text("\(LocalizedStrings.current.scale): \(String(format: "%.2f×", scale))")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesignSystem.Colors.secondaryText)
                    Spacer()
                    Button(action: {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                        onScaleChanged?(1.0)
                        onOffsetChanged?(.zero)
                    }) {
                        Text(LocalizedStrings.current.reset)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .glassCard(
                                cornerRadius: 6,
                                glassIntensity: 0.8
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                }

                Slider(value: $scale, in: 0.5...2.0, step: 0.01) {
                    Text(LocalizedStrings.current.scale)
                } minimumValueLabel: {
                    Text("0.5×").font(.caption2)
                } maximumValueLabel: {
                    Text("2.0×").font(.caption2)
                }
                .onChange(of: scale) { newValue in
                    onScaleChanged?(newValue)
                }
            }
        }
    }
}
