/// ImagePicker.swift
///
/// SwiftUI wrapper for UIImagePickerController
/// Allows users to select images from photo library
///
/// Created: 2025-10-21 (Epic 3 Prerequisite)

import SwiftUI
import UIKit

/// SwiftUI wrapper for UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {
    /// Binding to store selected image
    @Binding var image: UIImage?

    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        /// Called when user selects an image
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // Get selected image
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
            }

            // Dismiss picker
            parent.dismiss()
        }

        /// Called when user cancels
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    struct ImagePickerPreview: View {
        @State private var selectedImage: UIImage?
        @State private var showPicker = false

        var body: some View {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay {
                            Text("No image selected")
                                .foregroundColor(.secondary)
                        }
                }

                Button("Select Image") {
                    showPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .sheet(isPresented: $showPicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    return ImagePickerPreview()
}
