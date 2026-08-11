import SwiftUI
import UIKit

struct SkinTextureView: View {
    let imageData: Data

    var body: some View {
        Group {
            if let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .accessibilityLabel("Minecraft skin texture")
            } else {
                ContentUnavailableView(
                    "Preview unavailable",
                    systemImage: "photo.badge.exclamationmark"
                )
            }
        }
    }
}
