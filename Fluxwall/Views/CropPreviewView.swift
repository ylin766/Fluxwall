import SwiftUI

struct CropPreviewView: View {
    let displaySize: CGSize                         // 显示器分辨率
    let previewImage: NSImage                       // 生成的缩略图
    
    @Binding var scale: CGFloat                     // 缩放倍率
    @Binding var offset: CGSize                     // 拖动偏移
    var onScaleChanged: ((CGFloat) -> Void)? = nil
    var onOffsetChanged: ((CGSize) -> Void)? = nil

    @GestureState private var dragOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 12) {
            // 屏幕模拟器 + 缩略图预览
            ComputerFrameView(displaySize: displaySize) {
                GeometryReader { previewGeometry in
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
                                // 相对位置映射：预览窗口已经按实际显示器比例设计
                                // 所以我们直接使用预览容器中的拖拽距离作为相对偏移
                                // 然后按比例映射到实际显示器尺寸
                                let previewSize = previewGeometry.size
                                
                                // 计算相对偏移（百分比）
                                let relativeOffsetX = value.translation.width / previewSize.width
                                let relativeOffsetY = value.translation.height / previewSize.height
                                
                                // 将相对偏移应用到实际显示器尺寸
                                let actualOffsetX = relativeOffsetX * displaySize.width
                                let actualOffsetY = relativeOffsetY * displaySize.height
                                
                                let newOffset = CGSize(
                                    width: lastOffset.width + actualOffsetX,
                                    height: lastOffset.height + actualOffsetY
                                )
                                lastOffset = newOffset
                                offset = newOffset
                                onOffsetChanged?(newOffset)
                            }
                    )
                    .onChange(of: dragOffset) { newDrag in
                        // 实时预览时使用相同的相对位置映射
                        let previewSize = previewGeometry.size
                        
                        // 计算相对偏移（百分比）
                        let relativeOffsetX = newDrag.width / previewSize.width
                        let relativeOffsetY = newDrag.height / previewSize.height
                        
                        // 将相对偏移应用到实际显示器尺寸
                        let actualOffsetX = relativeOffsetX * displaySize.width
                        let actualOffsetY = relativeOffsetY * displaySize.height
                        
                        offset = CGSize(
                            width: lastOffset.width + actualOffsetX,
                            height: lastOffset.height + actualOffsetY
                        )
                    }
                }
            }
            .frame(height: 260)

            // 缩放控制滑块 + 重置按钮
            VStack(spacing: 4) {
                HStack {
                    Text("\(LocalizedStrings.current.scale): \(String(format: "%.2f×", scale))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
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
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .scaleEffect(1.0)

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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
        )
    }
}
